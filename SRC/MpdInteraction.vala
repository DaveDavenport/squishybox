/* Squishybox 
 * Copyright (C) 2010-2011 Qball Cow <qball@sarine.nl>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
using GLib;

namespace MPD
{
    private enum TaskType {
        CONNECT,
        DISCONNECT,
        PLAYER_PLAY,
        PLAYER_PLAY_ID,
        PLAYER_PLAY_POS,
        PLAYER_NEXT,
        PLAYER_PREVIOUS,
        PLAYER_PAUSE,
        PLAYER_STOP,
        PLAYER_SEEK,
        PLAYER_REPEAT,
        PLAYER_RANDOM,
        PLAYER_SINGLE_MODE,
        PLAYER_CONSUME_MODE,
        PLAYER_GET_CURRENT_SONG,

        MIXER_SET_VOLUME,

        PLAYER_GET_QUEUE,
        PLAYER_GET_QUEUE_POS,
        DATABASE_GET_DIRECTORY,

        QUEUE_SEARCH_ANY,
        QUEUE_ADD_SONG,

        CONNECTION_CHANGED,
        QUEUE_CHANGED,
        STATUS_CHANGED,
        ERROR_CALLBACK,
        QUIT
    }
    private delegate void GenericCallback (void *data);
    public delegate void CurrentSongCallback(MPD.Song? current_song);
    public delegate void EntityListCallback(List<MPD.Entity>? song_list);
    static int uid_c = 0;
    [Compact]
    private class Task{
        public Task()
        {
            uid = uid_c++;
        }
        public int      uid;
        public TaskType type;
        public GLib.Value param;

        public MPD.Status? status = null;
        public MPD.Song ? song = null;
        /* Vala does not allow me to pack this */
        public List<MPD.Entity>? entity_list = null;

        public GenericCallback callback;
        public CurrentSongCallback cscallback;
        public EntityListCallback slcallback;
    }


	public class Interaction : GLib.Object
	{
        private weak Thread<void*> command_thread ;
		private MPD.Connection connection = null;
        /* Async is owned by connection */
		private unowned MPD.Async async = null;
		private GLib.IOChannel io_channel = null;
		private MPD.Parser parser = new MPD.Parser();
		private uint watch_id {get; set; default=0;}



        /* Queue's for comunicating between threads */
        private AsyncQueue<MPD.Task?> command_queue = new AsyncQueue<MPD.Task?>();
        private AsyncQueue<MPD.Task?> result_queue = new AsyncQueue<MPD.Task?>();

		/**
		 * Signals
		 */
        private void do_error_callback(string error_message)
        {
            GLib.debug(error_message);
            /* Lock both queue's and empty them */
            result_queue.lock();
            command_queue.lock();
            /* Clear all results in the queu */
            while(result_queue.length_unlocked() > 0) result_queue.pop_unlocked();
            while(command_queue.length_unlocked() > 0) command_queue.pop_unlocked();

            Task t = new Task();
            t.type = TaskType.ERROR_CALLBACK;
            /* Force a copy */
            t.param = GLib.Value(typeof(string));
            t.param.set_string(error_message);
            result_queue.push_unlocked((owned)t);

            t = new Task();
            t.type = TaskType.DISCONNECT;
            command_queue.push_unlocked((owned)t);
            /* Do disconnect */
            io_channel = null;
            connection = null;
            result_queue.unlock();
            command_queue.unlock();
            GLib.Idle.add(process_result_queue);
        }
		public signal void error_callback(string error_message);

        /**
         * Database 
         */
        public void database_get_directory(EntityListCallback callback, string directory)
        {
            Task t = new Task();
            t.type = TaskType.DATABASE_GET_DIRECTORY;
            t.slcallback =  callback;
            t.param = GLib.Value(typeof(string));
            t.param.set_string(directory);
            command_queue.push((owned)t);
        }


		/**
		 *  Player Commands
		 */
         public void queue_add_song(string path)
         {
            Task t = new Task();
            t.type = TaskType.QUEUE_ADD_SONG;
            t.param = GLib.Value(typeof(string));
            t.param.set_string(path);
            command_queue.push((owned)t);
         }
        public void queue_search_any(EntityListCallback callback, string query)
        {
            Task t = new Task();
            t.type = TaskType.QUEUE_SEARCH_ANY;
            t.slcallback =  callback;
            t.param = GLib.Value(typeof(string));
            t.param.set_string(query);
            command_queue.push((owned)t);
        }
        public void player_get_queue_pos(CurrentSongCallback callback, uint pos)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_GET_QUEUE_POS;
            t.cscallback =  callback;
            t.param = GLib.Value(typeof(uint));
            t.param.set_uint(pos);
            command_queue.push((owned)t);
        }
        public void player_get_current_song(CurrentSongCallback callback)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_GET_CURRENT_SONG;
            t.cscallback =  callback;
            command_queue.push((owned)t);
        }
        public void player_get_queue(EntityListCallback callback)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_GET_QUEUE;
            t.slcallback =  callback;
            command_queue.push((owned)t);
        }
		public void player_next()
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_NEXT;
            command_queue.push((owned)t);
        } 
        public void player_previous()
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_PREVIOUS;
            command_queue.push((owned)t);
		} 
		public void player_toggle_pause()
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_PAUSE;
            command_queue.push((owned)t);
		} 
		public void player_stop()
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_STOP;
            command_queue.push((owned)t);
		} 
        public void player_seek(uint time)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_SEEK;
            t.param = GLib.Value(typeof(uint));
            t.param.set_uint(time);
            command_queue.push((owned)t);
        }
		public void player_play()
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_PLAY;
            command_queue.push((owned)t);
        }
		public void player_play_id(uint id)
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_PLAY_ID;
            t.param = GLib.Value(typeof(uint));
            t.param.set_uint(id);
            command_queue.push((owned)t);
        }
		public void player_play_pos(uint pos)
		{
            Task t = new Task();
            t.type = TaskType.PLAYER_PLAY_POS;
            t.param = GLib.Value(typeof(uint));
            t.param.set_uint(pos);
            command_queue.push((owned)t);
        }
        public void player_fetch_status()
        {
            Task t = new Task();
            t.type = TaskType.STATUS_CHANGED;
            command_queue.push((owned)t);
        }
        public void player_set_repeat(bool state)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_REPEAT;
            t.param = GLib.Value(typeof(bool));
            t.param.set_boolean(state);
            command_queue.push((owned)t);
        }
        public void player_set_random(bool state)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_RANDOM;
            t.param = GLib.Value(typeof(bool));
            t.param.set_boolean(state);
            command_queue.push((owned)t);
        }
        public void player_set_consume_mode(bool state)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_CONSUME_MODE;
            t.param = GLib.Value(typeof(bool));
            t.param.set_boolean(state);
            command_queue.push((owned)t);
        }
        public void player_set_single_mode(bool state)
        {
            Task t = new Task();
            t.type = TaskType.PLAYER_SINGLE_MODE;
            t.param = GLib.Value(typeof(bool));
            t.param.set_boolean(state);
            command_queue.push((owned)t);
        }

        public void mixer_set_volume(uint volume)
        {
            Task t = new Task();
            t.type = TaskType.MIXER_SET_VOLUME;
            t.param = GLib.Value(typeof(uint));
            t.param.set_uint(volume);
            command_queue.push((owned)t);
        }

        private bool process_result_queue()
        {
            Task? t = result_queue.try_pop(); 
            if(t != null)
            {
                GLib.debug("Processing result: %i", t.uid);
                if(t.type == TaskType.STATUS_CHANGED){
                    GLib.debug("Status changed");
                    unowned MPD.Status st = t.status; 
                    GLib.debug("status: %i\n", st.state);
                    player_status_changed(st);
                }else if (t.type == TaskType.QUEUE_CHANGED) {
                    GLib.debug("Queue changed");
                    player_queue_changed();
                } else if (t.type == TaskType.PLAYER_GET_CURRENT_SONG) {
                    unowned MPD.Song song = t.song;
                    t.cscallback(song);
                }  else if (t.type == TaskType.PLAYER_GET_QUEUE) {
                    t.slcallback(t.entity_list);
                }  else if (t.type == TaskType.QUEUE_SEARCH_ANY) {
                    t.slcallback(t.entity_list);
                } else if (t.type == TaskType.PLAYER_GET_QUEUE_POS) {
                    unowned MPD.Song song = t.song;
                    t.cscallback(song);
                } else if (t.type == TaskType.DATABASE_GET_DIRECTORY) {
                    t.slcallback(t.entity_list);
                } else if (t.type == TaskType.CONNECTION_CHANGED) {
                    player_connection_changed((this.connection == null)?false:true);
                } else if (t.type == TaskType.ERROR_CALLBACK) {
                     string ms = t.param.get_string();
                     error_callback(ms);
                }

            }
            if(result_queue.length() == 0) return false;
            return true;
        }

		/**
		 * We want to create signals here
		 */
		private void idle_state_changed(MPD.Idle.Events events)
		{
			if((events&MPD.Idle.Events.PLAYER) > 0 ||
                    (events&MPD.Idle.Events.OPTIONS) > 0 ||
                    (events&MPD.Idle.Events.MIXER) > 0
                ){
                Task t = new Task();
                t.type = TaskType.STATUS_CHANGED;
                t.status = connection.run_status();
                result_queue.push((owned)t);
            }
            if((events&MPD.Idle.Events.QUEUE) > 0){

                Task t = new Task();
                t.type = TaskType.QUEUE_CHANGED;
                result_queue.push((owned)t);
            }
            if(result_queue.length() > 0) {
                GLib.Idle.add(process_result_queue);
            }
		}

		public signal void player_status_changed(MPD.Status status);
		public signal void player_queue_changed();
		public signal void player_connection_changed(bool connected);
        

		/**
		 * Helper functions to convert from and to IOChannel from MPD.Async.Event
		 */
		private IOCondition convert_events(MPD.Async.Event condition)
		{
			IOCondition event=0;
			if((condition&MPD.Async.Event.READ) ==  MPD.Async.Event.READ){
				event |= IOCondition.IN;
			}
			if((condition&MPD.Async.Event.WRITE) ==  MPD.Async.Event.WRITE){
				event |= IOCondition.OUT;
			}
			if((condition&MPD.Async.Event.HUP) ==  MPD.Async.Event.HUP){
				event |= IOCondition.HUP;
			}
			if((condition&MPD.Async.Event.ERROR) ==  MPD.Async.Event.ERROR){
				event |= IOCondition.ERR;
			}
			return event;
		}
		private MPD.Async.Event convert_io_condition(IOCondition condition)
		{
			MPD.Async.Event event=0;
			if((condition&IOCondition.IN) ==  IOCondition.IN){
				event |= MPD.Async.Event.READ;
			}
			if((condition&IOCondition.OUT) ==  IOCondition.OUT){
				event |= MPD.Async.Event.WRITE;
			}
			if((condition&IOCondition.HUP) ==  IOCondition.HUP){
				event |= MPD.Async.Event.HUP;
			}
			if((condition&IOCondition.ERR) ==  IOCondition.ERR){
				event |= MPD.Async.Event.ERROR;
			}
			return event;
		}

		private bool watch_callback(IOChannel source, IOCondition condition)
        {
            /*lock(watch_id)*/
            command_queue.lock();
            if(condition == GLib.IOCondition.HUP) {
                GLib.warning("Error occured. %u", watch_id);
            }
            GLib.warning("watch callback called %i %i:%i:%i:%i:%i", condition,
                    GLib.IOCondition.IN,GLib.IOCondition.OUT,GLib.IOCondition.PRI,GLib.IOCondition.ERR, GLib.IOCondition.HUP);

            if(watch_id == 0) {
                GLib.warning("Idle canceld, ignoring");
                command_queue.unlock();
                return false;
            }
            MPD.Async.Event event = convert_io_condition(condition);;

            bool success = async.io(event);
            if(!success){
                GLib.warning("failed to read: %s", async.error_message);
                command_queue.unlock();
                do_error_callback("failed to read: %s".printf(async.error_message));
                return false;
            }


            /* There is new data to read */
            if((condition&IOCondition.IN) == IOCondition.IN) {
                /* Start reading response */
                string line = null;
                MPD.Idle.Events events = 0;
                while((line = async.recv_line()) != null) {
                    var result = parser.feed(line);
                    if(result == MPD.Parser.Result.PAIR) {
                        if(parser.get_name() == "changed") {
                            events |= MPD.Idle.name_parse(parser.get_value());
                        }
                    } else if (result == MPD.Parser.Result.SUCCESS) {
                        GLib.debug("Done parsing results");
                    }
                }
                if(event != 0) {
                    idle_state_changed(events);
                }
                /* Go back to idle mode */
                var suc = async.send_command("idle");
                if(!suc) {
                    command_queue.unlock();
                    do_error_callback("failed to send idle: %s".printf(async.get_error_message()));
                    GLib.critical("failed to send idle: %s", 
                            async.get_error_message());
                    return false;
                }
            }
            /* Reset the events */
            var events = async.get_events();
            var cond = convert_events(events);

            GLib.Source.remove(watch_id);

            if(events == 0){
                watch_id = 0;
                command_queue.unlock();
                return false;
            }

            watch_id = io_channel.add_watch(cond,
                    watch_callback);

            command_queue.unlock();
            return false;
        }
		private void start_idle()
		{
			/* If inside callback, ignore */

			GLib.debug("Start idle()");
			/* Start watching */
			var suc = async.send_command("idle");
			if(!suc) {
				GLib.critical("failed to send idle: %s", 
						async.get_error_message());
				do_error_callback("failed to send idle: %s".printf(async.get_error_message()));
                return;
			}
			create_watch();
		}

		private void stop_idle()
		{
            /*lock(watch_id) */
            {
                if(watch_id == 0) return;
                GLib.debug("Stop idle()");

                if(watch_id > 0) {
                    GLib.Source.remove(watch_id);
                    watch_id = 0;
                }
                var events = connection.run_noidle();
                if(events != 0) idle_state_changed(events);
            }
		}
		private void create_watch()
		{
            /*lock(watch_id)*/
            {
                /* Watch the channel */
                if(watch_id == 0){
                    watch_id = io_channel.add_watch(
                            GLib.IOCondition.IN|
                            GLib.IOCondition.OUT|
                            GLib.IOCondition.ERR|
                            GLib.IOCondition.HUP,
                            watch_callback);
                }
            }
		}

		/* Try to setup a connection to MPD */
        public bool check_connected()
        {
            return (connection != null);
        }
	public void mpd_connect()
	{
		Task t = new Task();
		t.type = TaskType.CONNECT;


		command_queue.push((owned)t);
	}
	public void mpd_disconnect()
	{
		Task t = new Task();
		t.type = TaskType.DISCONNECT;


		command_queue.push((owned)t);
	}
	private void mpd_connect_real()
	{
            io_channel = null;
            connection = new MPD.Connection(null,0, 5000);
            if(connection.get_error() != MPD.Error.SUCCESS)
            {
                GLib.critical("Failed to connect: %s\n",
                        connection.get_error_message());
                do_error_callback("Failed to connect: %s".printf(
                        connection.get_error_message()));

                connection = null;
                return;
            }
            /* Create Mpd.Async */ 
            async = connection.get_async();
            /* Tell that player has changed */
            Task t = new Task();
            t.type = TaskType.CONNECTION_CHANGED;
            result_queue.push((owned)t);
            t = new Task();
            t.type = TaskType.STATUS_CHANGED;
            t.status = connection.run_status();
            GLib.debug("got state: %i\n", ((MPD.Status)t.status).state);
            result_queue.push((owned)t);
            GLib.Idle.add(process_result_queue);
            /* Get IOChannel */
            io_channel = new GLib.IOChannel.unix_new(async.get_fd());
        }

        void *thread_func()
        {
            while(true)
            {
                var end = TimeVal();
                /* Wait 50 ms before dropping into idle mode */
                end.add(50000);
                /* Go back in idle when there is nothing todo */
//                if(connection != null && command_queue.length() == 0)
//                    start_idle();
                Task t = command_queue.timed_pop(ref end);
                if(t == null)
                {
                    if(connection != null) start_idle();
                    /* Get the next command to process */
                    /* Block! */
                    t = command_queue.pop();
                }

                /* Stop idle mode if we are in it */
                if(connection != null)
                    stop_idle();

                /* Process the task */
                GLib.debug("Processing task: %i", t.uid);
                /* Handle connect */
                if(t.type == TaskType.CONNECT)
                {
                    mpd_connect_real();
                }
                else if (t.type == TaskType.QUIT) {
                    GLib.debug("Command thread exiting.");
                    return null;
                }
                /* only do the following commands when connected */
                if(connection != null)
                {
                    /* Handle disconnect */
                    if (t.type == TaskType.DISCONNECT)
                    {
                        /*lock(watch_id) */
                        {
                            if(watch_id > 0) {
                                GLib.Source.remove(watch_id);
                                watch_id = 0;

                            }
                        }
                        this.io_channel = null;
                        this.async = null;
                        this.connection = null;

                        Task r = new Task();
                        r.type = TaskType.CONNECTION_CHANGED;
                        result_queue.push((owned)r);
                        GLib.Idle.add(process_result_queue);
                    }
                    else if (t.type == TaskType.PLAYER_PLAY) {
                        var suc = connection.player_run_play();
                        if(!suc) {
                            GLib.critical("failed to send play: %s\n", async.get_error_message());
                        }
                    }else if (t.type == TaskType.PLAYER_NEXT){
                        var suc = connection.player_run_next();
                        if(!suc) {
                            GLib.critical("failed to send next: %s\n", async.get_error_message());
                        }
                    }else if (t.type == TaskType.PLAYER_PREVIOUS){
                        var suc = connection.player_run_previous();
                        if(!suc) {
                            GLib.critical("failed to send previous: %s\n", async.get_error_message());
                        }
                    }else if (t.type == TaskType.PLAYER_PAUSE){
                        var suc = connection.player_run_toggle_pause();
                        if(!suc) {
                            GLib.critical("failed to send toggle_pause: %s\n", async.get_error_message());
                        }
                    }else if (t.type == TaskType.PLAYER_STOP){
                        var suc = connection.player_run_stop();
                        if(!suc) {
                            GLib.critical("failed to send toggle_pause: %s\n", async.get_error_message());
                        }
                    } else if (t.type == TaskType.PLAYER_GET_CURRENT_SONG) {
                        t.song = connection.run_current_song();
                        result_queue.push((owned)t);
                        GLib.Idle.add(process_result_queue);
                    } else if (t.type == TaskType.PLAYER_GET_QUEUE_POS) {
                        t.song = connection.run_get_queue_song_pos(t.param.get_uint());
                        result_queue.push((owned)t);
                        GLib.Idle.add(process_result_queue);
                    } else if (t.type == TaskType.PLAYER_SEEK) {
                        var song = connection.run_current_song();
                        if(song != null) {
                            if(!connection.player_run_seek_id(song.id, t.param.get_uint()))
                            {
                                do_error_callback("failed to seek: %s".
                                        printf(connection.get_error_message()));
                            }
                        }else{
                            do_error_callback("failed to get song: %s".
                                    printf(connection.get_error_message()));
                        }
                    } else if (t.type == TaskType.PLAYER_REPEAT) {
                        connection.run_repeat(t.param.get_boolean());
                    } else if (t.type == TaskType.PLAYER_RANDOM) {
                        connection.run_random(t.param.get_boolean());
                    } else if (t.type == TaskType.PLAYER_CONSUME_MODE) {
                        connection.run_consume(t.param.get_boolean());
                    } else if (t.type == TaskType.PLAYER_SINGLE_MODE) {
                        connection.run_single(t.param.get_boolean());
                    } else if (t.type == TaskType.PLAYER_PLAY_ID) {
                        if(!connection.player_run_play_id(t.param.get_uint()))
                        {
                            do_error_callback("failed to get playlist: %s".
                                    printf(connection.get_error_message()));
                        }
                    } else if (t.type == TaskType.PLAYER_PLAY_POS) {
                        if(!connection.player_run_play_pos(t.param.get_uint()))
                        {
                            do_error_callback("failed to get playlist: %s".
                                    printf(connection.get_error_message()));
                        }
                    } else if (t.type == TaskType.PLAYER_GET_QUEUE) {
                        if(connection.send_list_queue_meta())
                        {
                            MPD.Entity? entity;
                            List<MPD.Entity>? entitys = null;
                            while((entity = connection.recv_entity()) != null)
                            {
                                entitys.prepend((owned)entity);
                            }
                            if(!connection.response_finish()){
                                do_error_callback("failed to get playlist: %s".printf(connection.get_error_message()));
                            }else{
                                entitys.reverse();
                                Task j = new Task();
                                j.type = TaskType.PLAYER_GET_QUEUE;
                                j.slcallback = t.slcallback;
                                j.entity_list = (owned)entitys;
                                result_queue.push((owned)j);
                                GLib.Idle.add(process_result_queue);
                            }
                        }
                    }else if (t.type == TaskType.QUEUE_ADD_SONG) {
                        var path = t.param.get_string();
                        MPD.Queue.add(connection, path);

                    }else if (t.type == TaskType.QUEUE_SEARCH_ANY) {
                            MPD.Entity? entity;
                            List<MPD.Entity>? entitys = null;
                            if(connection.search_queue_songs(false))
                            {
                                connection.search_add_any_tag_constraint(MPD.Operator.DEFAULT, t.param.get_string());
                                connection.search_commit();	
                                while((entity = connection.recv_entity()) != null)
                                {
                                    entitys.prepend((owned)entity);
                                }
                                if(!connection.response_finish()){
                                    do_error_callback("failed to get playlist: %s".printf(connection.get_error_message()));
                                }else{
                                    entitys.reverse();
                                    Task j = new Task();
                                    j.type = TaskType.QUEUE_SEARCH_ANY;
                                    j.slcallback = t.slcallback;
                                    j.entity_list = (owned)entitys;
                                    result_queue.push((owned)j);
                                    GLib.Idle.add(process_result_queue);
                                }
                            }
                    }else if (t.type == TaskType.DATABASE_GET_DIRECTORY) {
                        MPD.Entity entity;
                        List<MPD.Entity>? entities = null;
                        connection.database_send_list_meta(t.param.get_string());
                        while((entity = connection.recv_entity()) != null)
                        {
                            entities.prepend((owned)entity);
                        }
                        if(!connection.response_finish()){
                            do_error_callback("failed to get directory: %s".printf(connection.get_error_message()));
                        }else{
                            entities.reverse();
                            Task j = new Task();
                            j.type = TaskType.DATABASE_GET_DIRECTORY;
                            j.slcallback = t.slcallback;
                            j.entity_list = (owned)entities;
                            result_queue.push((owned)j);
                            GLib.Idle.add(process_result_queue);
                        }
                    }
                    else if (t.type == TaskType.MIXER_SET_VOLUME) {
                        MPD.Mixer.set_volume(connection,t.param.get_uint());
                    }
                }

            }
        }


        /* Start it */
        public Interaction ()
        {
            try {
                command_thread = Thread.create<void*>(thread_func,true);
            }catch(ThreadError e){
                GLib.error("Failed to create thread: %s", e.message);
            }
        }
        ~Interaction ()
        {
            result_queue.lock();
            command_queue.lock();
            /* Clear all results in the queu */
            while(result_queue.length_unlocked() > 0) result_queue.pop_unlocked();
            while(command_queue.length_unlocked() > 0) command_queue.pop_unlocked();
            Task t = new Task();
            t.type = TaskType.QUIT;
            command_queue.push_unlocked((owned)t);
            result_queue.unlock();
            command_queue.unlock();
            void *a;
            a = command_thread.join();
            GLib.debug("Command thread destroyed");
        }
	}
}
