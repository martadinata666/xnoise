/* xnoise-worker.vala
 *
 * Copyright (C) 2009-2010  Jörn Magens
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  The Xnoise authors hereby grant permission for non-GPL compatible
 *  GStreamer plugins to be used and distributed together with GStreamer
 *  and Xnoise. This permission is above and beyond the permissions granted
 *  by the GPL license by which Xnoise is covered. If you modify this code
 *  you may extend this exception to your version of the code, but you are not
 *  obligated to do so. If you do not wish to do so, delete this exception
 *  statement from your version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA.
 *
 * Author:
 * 	Jörn Magens
 */




public class Worker : Object {
	
	private AsyncQueue<Job> async_job_queue = new AsyncQueue<Job>();
	private AsyncQueue<Job> sync_job_queue  = new AsyncQueue<Job>();
	
	private unowned Thread thread;
	
	private MainContext local_context;
	private MainContext main_context;
	
	public Worker(MainContext mc) {
		if (!Thread.supported ()) {
			error("Cannot work without multithreading support.");
		}
		this.main_context = mc;
		try {
			thread = Thread.create(thread_func, false );
		}
		catch(ThreadError e) {
			print("Error creating thread: %s\n", e.message);
		}
	}
	
	// AsyncWorkFunc will repeatedly be executed from an async function until it returns false
	public delegate bool AsyncWorkFunc(Job jb);
	
	// SyncWorkFunc will be executed in one shot as soon as the worker thread is idle
	public delegate void SyncWorkFunc(Job jb);
	
	public enum ExecutionType {
		UNKNOWN = 0,
		SYNC,
		SYNC_HIGH_PRIORITY, // not used,yet
		ASYNC,
		ASYNC_LOW_PRIORITY  // not used,yet
	}
	
	public class Job : Object {
		private HashTable<string,Value?> ht = new HashTable<string,Value?> (str_hash, str_equal);
		private ExecutionType _execution_type;
		
		public Job(int id = 0, 
		           ExecutionType execution_type = 0, 
		           AsyncWorkFunc? a_func = null,
		           SyncWorkFunc? s_func = null
		           ) {
			this.id = id;
			this._execution_type = execution_type;
			this.a_func = a_func;
			this.s_func = s_func;
		}
		
		// using the setter/getter will use a copy of the values for simple types, strings, arrays and structs
		// only for classes a reference is used
		public void set_arg(string? name, Value? val) {
			if(name == null)
				return;
			this.ht.insert(name, val);
		}
		public Value? get_arg(string name) {
			return this.ht.lookup(name);
		}
		
		~Job() {
			this.ht.remove_all();
			print("dtor job\n"); 
		}
		
		// These can be used as references to other objects, structs, arrays, simple types, strings, arrays and structs
		public Value? value_arg1 = null;
		public Value? value_arg2 = null;
		public void* p_arg = null;
		
		// It is useful to have some Job persistent counters available
		public int counter[4];
		
		// Finished signals will be sent in the main thread
		public signal void finished();
		
		// This can be used to identify the job or it's origin, etc.
		// This could also be used to mark the creation time of a job, if useful
		public int64 id;
		
		// readonly execution type for the job (sync, async, ..)
		public ExecutionType execution_type { get { return _execution_type; } }
		
		public AsyncWorkFunc? a_func = null;
		public SyncWorkFunc?  s_func = null;
		public Cancellable? cancellable = null;
	}
	
	//thread function is used to setup a local mainloop/maincontext
	private void* thread_func() {
		local_context = new MainContext();
		local_context.push_thread_default();
		var loop = new MainLoop(local_context);
		loop.run();
		return null;
	}
	
	// Execution of async jobs
	private async void async_func() {
		Job current_job = async_job_queue.try_pop();
		if(current_job == null) {
			print("no async job\n");
			return;
		}
		bool repeat = true;
		while(repeat) {
			//message( "thread %d ; job %d", (int)Linux.gettid(), current_job.id);
			repeat = current_job.a_func(current_job);
			var source = new IdleSource();
			source.set_callback(async_func.callback);
			//execute async function in local context
			source.attach(local_context);
			yield;
		}
		Source s2 = new IdleSource(); 
		s2.set_callback(() => {
			//send Job's finished signal in main context
			current_job.finished();
			return false;
		});
		s2.attach(main_context);
	}
	
	// Execution of sync jobs
	private void sync_func() {
		Job current_job = sync_job_queue.try_pop();
		if(current_job == null) {
			print("no sync job\n");
			return;
		}
		//message( "thread %d ; sync job %d", (int)Linux.gettid(), current_job.id);
		current_job.s_func(current_job);
		Source s2 = new IdleSource(); 
		s2.set_callback(() => {
			current_job.finished();
			return false;
		});
		s2.attach(main_context);
	}
	
	// After pushing a Job, it will be executed and removed
	public void push_job(Job j) {
		switch(j.execution_type) {
			case ExecutionType.SYNC:
				if(j.s_func == null) {
					print("Error: There must be a SyncWorkFunc in a sync job.\n");
					break;
				}
				try {
					sync_job_queue.push(j);
				}
				catch(ThreadError e) {
					print("Error pushing to thread pool: %s\n", e.message);
				}
				Source source = new IdleSource(); 
				source.set_callback(() => {
					sync_func(); 
					return false;
				});
				source.attach(local_context);
				break;
			case ExecutionType.ASYNC:
				if(j.a_func == null) {
					print("Error: There must be a AsyncWorkFunc in an async job.\n");
					break;
				}
				try {
					async_job_queue.push(j);
				}
				catch(ThreadError e) {
					print("Error pushing to thread pool: %s\n", e.message);
				}
				Source source = new IdleSource(); 
				source.set_callback(() => {
					async_func(); 
					return false;
				});
				source.attach(local_context);
				break;
			default:
				print("Not a valid execution type. Doing nothing\n");
				break;
		}
	}
}

