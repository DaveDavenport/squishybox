/**
 * Quick and dirty wrapper for libmpdclient2
 */
[CCode (cheader_filename="mpd/client.h")]
namespace MPD
{
            [CCode (cprefix="MPD_OPERATOR_", cname="enum mpd_operator")]
            public enum Operator {
			DEFAULT;
		}
        [CCode (cname = "struct mpd_async",
            free_function = "mpd_async_free",
            cheader_filename = "mpd/async.h")]
        [Compact]
        [Immutable]
        public class Async 
        {
            [CCode (cprefix="MPD_ASYNC_EVENT_", cname="enum mpd_async_event")]
            public enum Event {
                READ = 1,
                WRITE = 2,
                HUP = 4,
                ERROR = 8
            }

            /**
             * Creates a new asynchronous MPD connection, based on a stream socket
             * connected with MPD.
             *
             * @param fd the socket file descriptor of the stream connection to MPD
             * @return a mpd_async object, or NULL on out of memory
             */
            public Async (int fd);

            /**
             * Returns the file descriptor which should be polled by the caller.
             * Do not use the file descriptor for anything except polling!  The
             * file descriptor never changes during the lifetime of this
             * #mpd_async object.
             */

            public int get_fd();
            /**
             * After an error has occurred, this function returns the error code.
             * If no error has occurred, it returns #MPD_ERROR_SUCCESS.
             */
            public MPD.Error get_error();
            public MPD.Error error {get;}

            
            /**
             * If mpd_async_is_alive() returns false, this function returns the
             * human readable error message which caused this.  This message is
             * optional, and may be NULL.  The pointer is invalidated by
             * mpd_async_free().
             *
             * For #MPD_ERROR_SERVER, the error message is encoded in UTF-8.
             * #MPD_ERROR_SYSTEM obtains its error message from the operating
             * system, and thus the locale's character set (and probably language)
             * is used.  Keep that in mind when you print error messages.
             */
             public unowned string? get_error_message();
             public unowned string? error_message {get;}

             /**
              * Returns the error code from the operating system; on most operating
              * systems, this is the errno value.  Calling this function is only
              * valid if mpd_async_get_error() returned #MPD_ERROR_SYSTEM.
              *
              * May be 0 if the operating system did not specify an error code.
              */
             public int get_system_error();
             public int system_error {get;}

             /**
              * Returns a bit mask of events which should be polled for.
              */
             [CCode (cname="mpd_async_events")]
             public MPD.Async.Event get_events();
             


             /**
              * Call this function when poll() has returned events for this
              * object's file descriptor.  libmpdclient will attempt to perform I/O
              * operations.
              *
              * @return false if the connection was closed due to an error
              */
              public bool io(MPD.Async.Event events);

              /**
               * Appends a command to the output buffer.
               *
               * @param async the connection
               * @param command the command name, followed by arguments, terminated by
               * NULL
               * @param args the argument list
               * @return true on success, false if the buffer is full
               */
               /* TODO, how do I do this in vala ? 
              public bool send_command_v(string command,va_list args);
                */

              /**
               * Appends a command to the output buffer.
               *
               * @param async the connection
               * @param command the command name, followed by arguments, terminated by
               * NULL
               * @return true on success, false if the buffer is full
               */
              public bool send_command(string command,...);

              /**
               * Receives a line from the input buffer.  The result will be
               * null-terminated, without the newline character.  The pointer is
               * only valid until the next async function is called.gg
               *
               * @param async the connection
               * @return a line on success, NULL otherwise
               */
              public unowned string? recv_line();

              /* DATABASE.h */
              /**
               * Get a recursive list of all directories, songs and playlist from
               * MPD.  They are returned without metadata.  This is a rather
               * expensive operation, because the response may be large.
               *
               * @param connection the connection to MPD
               * @param path an optional base path for the query
               * @return true on success, false on error
               */
               [CCode (cname="mpd_send_list_all")]
              public bool database_send_list_all(string path);

              /**
               * Like #mpd_send_list_all(), but return metadata.  This operation is
               * even more expensive, because the response is larger.  If it is
               * larger than a configurable server-side limit, MPD may disconnect
               * you.
               *
               * To read the response, you may use mpd_recv_entity().
               *
               * @param connection the connection to MPD
               * @param path an optional base path for the query
               * @return true on success, false on error
               */
               [CCode (cname="mpd_send_list_all_meta")]
              public bool database_send_list_all_meta( string path);


              /**
               * Get a list of all directories, songs and playlist in a directory
               * from MPD, including metadata.
               *
               * To read the response, you may use mpd_recv_entity().
               *
               * @param connection the connection to MPD
               * @param path the directory to be listed
               * @return true on success, false on error
               */
               [CCode (cname="mpd_send_list_meta")]
              public bool database_send_list_meta( string path);

              /**
               * Instructs MPD to update the music database: find new files, remove
               * deleted files, update modified files.
               *
               * @param connection the connection to MPD
               * @param path optional path to update; if NULL, then all of the music
               * directory is updated
               * @return true on success, false on error
               */
               [CCode (cname="mpd_send_update")]
              public bool database_send_update( string path);

              /**
               * Like mpd_send_update(), but also rescans unmodified files.
               *
               * @param connection the connection to MPD
               * @param path optional path to update; if NULL, then all of the music
               * directory is updated
               * @return true on success, false on error
               */
               [CCode (cname="mpd_send_rescan")]
               public bool database_send_rescan( string path);

              /**
               * Receives the id the of the update job which was submitted by
               * mpd_send_update().
               *
               * @param connection the connection to MPD
               * @return a positive job id on success, 0 on error
               */
              [CCode (cname="mpd_recv_update_id")]
              public uint database_recv_update_id();

              /**
               * Shortcut for mpd_send_update() and mpd_recv_update_id().
               *
               * @param connection the connection to MPD
               * @param path optional path to update; if NULL, then all of the music
               * directory is updated
               * @return a positive job id on success, 0 on error
               */
              [CCode (cname="mpd_run_update")]
              public uint database_run_update( string path);

              /**
               * Like mpd_run_update(), but also rescans unmodified files.
               *
               * @param connection the connection to MPD
               * @param path optional path to update; if NULL, then all of the music
               * directory is updated
               * @return a positive job id on success, 0 on error
               */
              [CCode (cname="mpd_run_rescan")]
              public uint database_run_rescan( string path);


        }

        [CCode (cname = "struct mpd_connection",
                free_function = "mpd_connection_free",
                cheader_filename = "mpd/client.h")]
        [Compact]
        [Immutable]
        public class Connection
        {
            /**
             * Opens a new connection to a MPD server.  Both the name server
             * lookup and the connect() call are done synchronously.  After this
             * function has returned, you should check if the connection was
             * successful with mpd_connection_get_error().
             *
             * @param host the server's host name, IP address or Unix socket path.
             * If the resolver returns more than one IP address for a host name,
             * this functions tries all of them until one accepts the connection.
             * NULL is allowed here, which will connect to the default host.
             * @param port the TCP port to connect to, 0 for default port.  If
             * "host" is a Unix socket path, this parameter is ignored.
             * @param timeout_ms the timeout in milliseconds, 0 for the default
             * timeout; you may modify it later with mpd_connection_set_timeout()
             * @return a mpd_connection object (which may have failed to connect),
             * or NULL on out-of-memory
             */
            public Connection(string? host, int port, uint timeout);

            /**
             * Creates a #mpd_connection object based on an existing asynchronous
             * MPD connection.  You should not continue to use the #mpd_async
             * object.  Note that mpd_connection_free() also frees your #mpd_async
             * object!
             *
             * This function does not block at all, which is why you have to pass
             * the welcome message to it.
             *
             * @param async a #mpd_async instance
             * @param welcome the first line sent by MPD (the welcome message)
             * @return a mpd_connection object, or NULL on out-of-memory
             */
            [CCode (cname="mpd_connection_new_async")]
                public Connection.from_async(MPD.Async async, string welcome);

            /**
             * Sets the timeout for synchronous operations.  If the MPD server
             * does not send a response during this time span, the operation is
             * aborted by libmpdclient.
             *
             * The initial value is the one passed to mpd_connection_new().  If
             * you have used mpd_connection_new_async(), then the default value is
             * 30 seconds.
             *
             * @param connection the connection to MPD
             * @param timeout_ms the desired timeout in milliseconds; must not be 0
             */
            public void set_timeout(uint timeout);
            public int timeout {
                [CCode (cname="mpd_connection_set_timeout_real")]
                    set { this.set_timeout(value);}
            }
            /**
             * Returns the file descriptor which should be polled by the caller.
             * Do not use the file descriptor for anything except polling!  The
             * file descriptor never changes during the lifetime of this
             * #mpd_connection object.
             */
            public int get_fd();
            public int fd {
                [CCode (cname="mpd_connection_get_fd_real")]
                    get { this.get_fd();}
            }

            /**
             * Returns the underlying #mpd_async object.  This can be used to send
             * commands asynchronously.  During an asynchronous command, you must
             * not use synchronous #mpd_connection functions until the
             * asynchronous response has been finished.
             *
             * If an error occurs while using #mpd_async, you must close the
             * #mpd_connection.
             */
            public unowned MPD.Async get_async();
            public unowned MPD.Async async{
                [CCode (cname="mpd_connection_get_async_real")]
                    get { this.get_async();}
            }
            /**
             * Returns the libmpdclient error code.  MPD.Error.SUCCESS means no
             * error occurred.
             */
            public MPD.Error get_error();
            /**
             * Returns the human-readable (English) libmpdclient error message.
             * Calling this function is only valid if an error really occurred.
             * Check with mpd_connection_get_error().
             *
             * For #MPD_ERROR_SERVER, the error message is encoded in UTF-8.
             * #MPD_ERROR_SYSTEM obtains its error message from the operating
             * system, and thus the locale's character set (and probably language)
             * is used.  Keep that in mind when you print error messages.
             */
            public unowned string? get_error_message();

            /**
             * Returns the error code returned from the server.  Calling this
             * function is only valid if mpd_connection_get_error() returned
             * #MPD_ERROR_SERVER.
             */
            public MPD.ServerError get_server_error();

            /**
             * Returns the error code from the operating system; on most operating
             * systems, this is the errno value.  Calling this function is only
             * valid if mpd_connection_get_error() returned #MPD_ERROR_SYSTEM.
             *
             * May be 0 if the operating system did not specify an error code.
             */
            public int get_system_error();

            /**
             * Attempts to recover from an error condition.  This function must be
             * called after a non-fatal error before you can continue using this
             * object.
             *
             * @return true on success, false if the error is fatal and cannot be
             * recovered
             */
            public bool clear_error();

            /**
             * Returns a three-tuple containing the major, minor and patch version
             * of the MPD protocol.
             */

            [CCode (array_length=false)]
            public unowned uint[] get_server_version();

            public unowned uint[] server_version{
                [CCode (cname="mpd_connection_get_server_version_real")]
                get { return this.get_server_version(); }
            }
            /**
             * Compares the MPD protocol version with the specified triple.
             *
             * @return -1 if the server is older, 1 if it is newer, 0 if it is
             * equal
             */
            public int cmp_server_version(uint major, uint minor, uint patch);


            /* RESPONSE.H */

            /**
             * Finishes the response and checks if the command was successful.  If
             * there are data pairs left, they are discarded.
             *
             * @return true on success, false on error
             */
            [CCode (cname="mpd_response_finish")]
            public bool response_finish();

            /**
             * Finishes the response of the current list command.  If there are
             * data pairs left, they are discarded.
             *
             * @return true on success, false on error
             */
            [CCode (cname="mpd_response_next")]
            public bool response_next();

            /* STATUS. H */
            /**
             * Executes the "status" command and reads the response.
             *
             * @return the #mpd_status object returned by the server, or NULL on
             * error
             */
            [CCode (cname="mpd_run_status")]
            public MPD.Status run_status();

            /**
             * Sends the "status" command to MPD.  Call mpd_recv_status() to read
             * the response.
             *
             * @return true on success
             */
            [CCode (cname="mpd_send_status")]
            public bool send_status();

            /**
             * Receives a #mpd_status object from the server.
             *
             * @return the received #mpd_status object, or NULL on error
             */
            [CCode (cname="mpd_recv_status")]
            public MPD.Status recv_status();

            /* CAPABILITIES.h */
            /**
             * Requests a list of supported and allowed.  Use
             * mpd_recv_pair_named() to obtain the list of "command" pairs.
             *
             * @param connection the connection to MPD
             * @return true on success, false on error
             */
            public bool send_allowed_commands();

            /**
             * Requests a list of supported commands which are not allowed for
             * this connection.  Use mpd_recv_pair_named() to obtain the list of
             * "command" pairs.
             *
             * @param connection the connection to MPD
             * @return true on success, false on error
             */
            public bool send_disallowed_commands();

            /**
             * Receives the next supported command.  Call this in a loop after
             * mpd_send_commands() or mpd_send_notcommands().
             *
             * Free the return value with mpd_return_pair().
             *
             * @param connection a #mpd_connection
             * @returns a "command" pair, or NULL on error or if the end of the
             * response is reached
             */
            public MPD.Pair? recv_command_pair();

            /**
             * Requests a list of supported URL handlers in the form "scheme://",
             * example: "http://".  Use mpd_recv_pair_named() to obtain the list
             * of "handler" pairs.
             *
             * @param connection the connection to MPD
             * @return true on success, false on error
             */
            public bool send_list_url_schemes();

            /**
             * Receives one line of the mpd_send_urlhandlers() response.
             *
             * Free the return value with mpd_return_pair().
             *
             * @param connection a #mpd_connection
             * @returns a "handler" pair, or NULL on error or if the end of the
             * response is reached
             */
            public MPD.Pair? recv_url_scheme_pair();

            /**
             * Requests a list of supported tag types.  Use mpd_recv_pair_named()
             * to obtain the list of "tagtype" pairs.
             *
             * @param connection the connection to MPD
             * @return true on success, false on error
             */
            public bool send_list_tag_types();

            /**
             * Receives the next tag type name.  Call this in a loop after
             * mpd_send_tagtypes().
             *
             * Free the return value with mpd_return_pair().
             *
             * @param connection a #mpd_connection
             * @returns a "handler" pair, or NULL on error or if the end of the
             * response is reached
             */
            public  MPD.Pair? recv_tag_type_pair();
            
            [CCode (cname="mpd_run_next")]
            public bool player_run_next();
            [CCode (cname="mpd_run_previous")]
            public bool player_run_previous();
            [CCode (cname="mpd_run_toggle_pause")]
            public bool player_run_toggle_pause();
            [CCode (cname="mpd_run_stop")]
            public bool player_run_stop();
            [CCode (cname="mpd_run_play")]
            public bool player_run_play();
            [CCode (cname="mpd_run_play_id")]
            public bool player_run_play_id(uint song_id);
            [CCode (cname="mpd_run_seek_id")]
            public bool player_run_seek_id(uint song_id, uint ntime);
            [CCode (cname="mpd_run_play_pos")]
            public bool player_run_play_pos(uint song_pos);
            [CCode (cname="mpd_run_noidle")]
            public MPD.Idle.Events run_noidle();

            [CCode (cname="mpd_run_repeat")]
            public bool run_repeat(bool state);

            [CCode (cname="mpd_run_random")]
            public bool run_random(bool state);
            [CCode (cname="mpd_run_single")]
            public bool run_single(bool state);
            [CCode (cname="mpd_run_consume")]
            public bool run_consume(bool state);

            [CCode (cname ="mpd_run_current_song")]
            public MPD.Song? run_current_song();

	    [CCode (cname = "mpd_search_queue_songs")]
	    public bool search_queue_songs(bool exact);
	    [CCode (cname = "mpd_search_add_any_tag_constraint")]
	    public bool search_add_any_tag_constraint(MPD.Operator oper, string value);
	    [CCode (cname = "mpd_search_commit")]
	    public bool search_commit();

            [CCode (cname ="mpd_send_list_queue_meta")]
            public bool send_list_queue_meta();
            [CCode (cname="mpd_recv_song")]
            public MPD.Song? recv_song();



            /**
             * Receives the next entity from the MPD server.
             *
             * @return an entity object, or NULL on error or if the entity list is
             * finished
             */
            [CCode (cname="mpd_recv_entity", cheader_filename="mpd/entity.h")]
            public MPD.Entity? recv_entity();


            [CCode (cname="mpd_run_get_queue_song_pos")]
            public MPD.Song? run_get_queue_song_pos(uint pos);

            /**
             * Get a list of all directories, songs and playlist in a directory
             * from MPD, including metadata.
             *
             * To read the response, you may use mpd_recv_entity().
             *
             * @param connection the connection to MPD
             * @param path the directory to be listed
             * @return true on success, false on error
             */
            [CCode (cname="mpd_send_list_meta")]
            public bool database_send_list_meta(string directory);
        }
        
        /**
         * A name-value pair received from the MPD server.
         */
         [CCode (cname="mpd_pair", cheader_filename="mpd/client.h")]
        public struct Pair {
            /** the name of the element */
            public unowned string name;

            /** the name of the element */
            public unowned string value;
        }

        [CCode (cname="struct mpd_audio_format", free_function="mpd_return_pair", cheader_filename="mpd/client.h")]
        public struct AudioFormat {
            /**
             * The sample rate in Hz.  A better name for this attribute is
             * "frame rate", because technically, you have two samples per
             * frame in stereo sound.
             */
            public uint32 sample_rate;
            /**
             * The number of significant bits per sample.  Samples are
             * currently always signed.  Supported values are 8, 16, 24,
             * 32.  24 bit samples are packed in 32 bit integers.
             */
            public uint8 bits;
            /**
             * The number of channels.  Only mono (1) and stereo (2) are
             * fully supported currently.
             */
            public uint8 channels;

            /** Reserved for future use */
            private uint16 reserved0;
            private uint32 reserved1;

        }

        [CCode (cname = "struct mpd_status",
            free_function = "mpd_status_free",
            cheader_filename = "mpd/client.h")]
        [Compact]
        [Immutable]
        public class Status {
            [CCode (cprefix="MPD_STATE_",cname="enum mpd_state")]
            public enum State {
                UNKOWN = 0,
                STOP = 1,
                PLAY = 2,
                PAUSE = 3
            }
            /**
             * Returns the current volume: 0-100, or -1 when there is no volume
             * support.
             */
            public int get_volume();
            public int volume {
                get;
            }
            /**
             * Returns true if repeat mode is on.
             */
            public bool get_repeat();
            public bool repeat {
                get;
            }

            /**
             * Returns true if random mode is on.
             */
            public bool get_random();
            public bool random {
                get;
            }

            /**
             * Returns true if single mode is on.
             */
            public bool get_single();
            public bool single {
                get;
            }

            /**
             * Returns true if consume mode is on.
             */
            public bool get_consume();
            public bool consume {
                get;
            }

            /**
             * Returns the number of songs in the queue.  If MPD did not
             * specify that, this function returns 0.
             */
            public uint get_queue_length();
            public uint queue_length { get;}


            /**
             * Returns queue version number.  You may use this to determine
             * when the queue has changed since you have last queried it.
             */
            public uint get_queue_version();
            public uint queue_version { get;}

            /**
             * Returns the state of the player: either stopped, playing or paused.
             */
            public MPD.Status.State get_state();
            public MPD.Status.State state {get;}

            /* Returns crossfade setting in seconds.  0 means crossfading is
             * disabled.
             */
            public uint get_crossfade();
            public uint crossfase {get;}

            /**
             * Returns the position of the currently playing song in the queue
             * (beginning with 0) if a song is currently selected (always the case when
             * state is PLAY or PAUSE).  If there is no current song, -1 is returned.
             */
            public int get_song_pos();
            public int song_pos {get;}

            /**
             * Returns the id of the currently song.  If there is no current song,
             * -1 is returned.
             */
            public int get_song_id();
            public int song_id {get;}

            /**
             * Returns time in seconds that have elapsed in the currently playing/paused
             * song
             */
            public uint get_elapsed_time();
            public uint elapsed_time {get;}

            /**
             * Returns time in milliseconds that have elapsed in the currently
             * playing/paused song.
             */
            public uint get_elapsed_ms();
            public uint elapsed_ms {get;}
            /**
             * Returns the length in seconds of the currently playing/paused song
             */
            public uint get_total_time();
            public uint total_time {get;}

            /**
             * Returns current bit rate in kbps.  0 means unknown.
             */
            public uint get_kbit_rate();
            public uint kbit_rate {get;}

            /**
             * Returns audio format which MPD is currently playing.  May return
             * NULL if MPD is not playing or if the audio format is unknown.
             */
            public unowned MPD.AudioFormat? get_audio_format();
            public unowned MPD.AudioFormat? audio_format {
                    [CCode (cname="mpd_status_get_audio_format_real")]
                    get { return this.get_audio_format();}
            }

            /**
             * Returns 1 if mpd is updating, 0 otherwise
             */
            public uint get_update_id();

            /**
             * Returns the error message
             */
            public unowned string? get_error();
            public unowned string? error {get;}
        }

        [Ccode (cheader_filename = "mpd/client.h", cname="enum mpd_server_error")]
        public enum ServerError {
            UNK = -1,
            NOT_LIST = 1,
            ARG = 2,
            PASSWORD = 3,
            PERMISSION = 4,
            UNKNOWN_CMD = 5,
            NO_EXIST = 50,
            PLAYLIST_MAX = 51,
            SYSTEM = 52,
            PLAYLIST_LOAD = 53,
            UPDATE_ALREADY = 54,
            PLAYER_SYNC = 55,
            EXIST = 56
        }


        [CCode (cheader_filename = "mpd/client.h", cname="enum mpd_error")]
        public enum Error {
            /** no error */
            SUCCESS = 0,
            /** out of memory */
            OOM,
            /** a function was called with an unrecognized or invalid argument */
            ARG,
            /** a function was called which is not available in the current state of libmpdclient */
            STATE,
            /** timeout trying to talk to mpd */
            TIMEOUT = 10,
            /** system error */
            SYSTEM,
            /** unknown host */
            UNKHOST,
            /** problems connecting to port on host */
            CONNPORT,
            /** mpd not running on port at host */
            NOTMPD,
            /** no response on attempting to connect */
            NORESPONSE,
            /** error sending command */
            SENDING,
            /** malformed response received from MPD */
            MALFORMED,
            /** connection closed by mpd */
            CONNCLOSED,
            /** ACK returned! */
            ACK,
            /** Buffer was overrun! */
            BUFFEROVERRUN
        }
        [CCode (cname = "struct mpd_parser",
            free_function = "mpd_parser_free",
            cheader_filename = "mpd/parser.h")]
        [Compact]
        [Immutable]
        public class Parser 
        {
          [CCode (cprefix="MPD_PARSER_",cname="enum mpd_parser_result")]
          public enum Result {
            MALFORMED,
            SUCCESS,
            ERROR,
            PAIR
          }
          public Parser();
          
          public Parser.Result feed(string line);
          public unowned string get_name();
          public unowned string get_value();
        }
        
        namespace Idle
        {
          [CCode (cprefix="MPD_IDLE_", cname="enum mpd_idle", cheader_file="mpd/idle.h")]
          public enum Events 
          {
            DATABASE = 0x1,
            STORED_PLAYLIST =0x2,
            QUEUE = 0x4,
            PLAYER = 0x8,
            MIXER = 0x10,
            OUTPUT= 0x20,
            OPTIONS = 0x40,
            UPDATE = 0x80
          }
          public Events name_parse(string? idle_name);
        }


        namespace Tag
        {
                [CCode (cprefix="MPD_TAG_", cname="enum mpd_tag_type")]
                public enum Type {
                        UNKNOWN = -1,
                        ARTIST,
                        ALBUM,
                        ALBUM_ARTIST,
                        TITLE,
                        TRACK,
                        NAME,
                        GENRE,
                        DATE,
                        COMPOSER,
                        PERFORMER,
                        COMMENT,
                        DISC,

                        MUSICBRAINZ_ARTISTID,
                        MUSICBRAINZ_ALBUMID,
                        MUSICBRAINZ_ALBUMARTISTID,
                        MUSICBRAINZ_TRACKID,

                        COUNT

                }
        }
        [CCode (cname = "struct mpd_song",
            free_function = "mpd_song_free",
            copy_function = "mpd_song_dup",
            cheader_filename = "mpd/song.h")]
        [Compact]
        [Immutable]
        public class Song 
        {
                public unowned string get_uri();
                public unowned string uri { get; }

                public unowned uint get_pos();
                public unowned uint pos { get; }

                public unowned uint get_id();
                public unowned uint id { get; }


                public unowned string get_tag(MPD.Tag.Type tag, uint index);
        }

        [CCode (cname = "struct mpd_directory",
            free_function = "mpd_directory_free",
            copy_function = "mpd_directory_dup",
            cheader_filename = "mpd/directory.h")]
        [Compact]
        [Immutable]
        public class Directory
        {
                /**
                 * Returns the path of this directory, relative to the MPD music
                 * directory.  It does not begin with a slash.
                 */
                public unowned string get_path();
                /**
                 * Returns the path of this directory, relative to the MPD music
                 * directory.  It does not begin with a slash.
                 */
                public unowned string path { get;}
        }

        [CCode (cname = "struct mpd_entity",
            free_function = "mpd_entity_free",
            cheader_filename = "mpd/entity.h")]
        [Compact]
        [Immutable]
        public class Entity
        {
                /**
                 * The type of a #mpd_entity object.
                 */
                 [CCode (cname="enum mpd_entity_type")]
                public enum Type {
                        /**
                         * The type of the entity received from MPD is not implemented
                         * in this version of libmpdclient.
                         */
                        UNKNOWN,

                        /**
                         * A directory (#mpd_directory) containing more entities.
                         */
                        DIRECTORY,

                        /**
                         * A song file (#mpd_song) which can be added to the playlist.
                         */
                        SONG,

                        /**
                         * A stored playlist (#mpd_playlist).
                         */
                        PLAYLIST,
                }

                /**
                 * @return the type of this entity.
                 */
                public MPD.Entity.Type get_type(); 

                /**
                 * Obtains a pointer to the #mpd_directory object enclosed by this
                 * #mpd_entity.  Calling this function is only allowed of
                 * mpd_entity_get_type() has returned #MPD_ENTITY_TYPE_DIRECTORY.
                 *
                 * @return the directory object
                 */
                public unowned MPD.Directory? get_directory();

                /**
                 * Obtains a pointer to the #mpd_song object enclosed by this
                 * #mpd_entity.  Calling this function is only allowed of
                 * mpd_entity_get_type() has returned #MPD_ENTITY_TYPE_SONG.
                 *
                 * @return the song object
                 */
                 public unowned MPD.Song? get_song();
        }
}

/* vim: set expandtab ts=8 sw=8 sts=8 tw=80: */
