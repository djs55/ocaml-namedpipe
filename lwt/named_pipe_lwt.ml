(*
 * Copyright (c) 2016 Docker Inc
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Lwt

exception Not_available

let () = Callback.register_exception "named-pipe.lwt:not-available" Not_available


module Server = struct
  type t = Unix.file_descr
  let to_fd x = Lwt_unix.of_unix_file_descr ~blocking:true x

  external create: string -> t = "stub_named_pipe_create"

  external connect_job: t -> bool Lwt_unix.job = "named_pipe_lwt_connect_job"

  let connect t = Lwt_unix.run_job (connect_job t)

  external flush_job: t -> unit Lwt_unix.job = "named_pipe_lwt_flush_job"

  let flush t = Lwt_unix.run_job (flush_job t)

  external disconnect: t -> unit = "stub_named_pipe_disconnect"

  external destroy: t -> unit = "stub_named_pipe_destroy"
end

module Client = struct
  type t = Unix.file_descr
  let to_fd x = x

  let to_fd x = Lwt_unix.of_unix_file_descr ~blocking:true x

  external wait_job: string -> int -> bool Lwt_unix.job = "named_pipe_lwt_wait_job"

  let wait path ms = Lwt_unix.run_job (wait_job path ms)

  let rec openpipe path =
    if Sys.os_type <> "Win32" then raise Not_available;
    try
      let fd = Unix.openfile path [ Unix.O_RDWR ] 0 in
      Lwt.return fd
    with Unix.Unix_error(Unix.EUNKNOWNERR -231, _, _) ->
      (* ERROR_PIPE_BUSY *)
      wait path 1000
      >>= fun _ ->
      openpipe path
    | e -> raise e

end
