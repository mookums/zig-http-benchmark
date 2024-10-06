#![feature(core_intrinsics, asm)]
#![feature(start, lang_items)]
#![allow(clippy::missing_safety_doc, unused_imports, dead_code)]

use core::intrinsics::likely;
use faf::const_concat_bytes;
use faf::const_http::*;
use faf::util::{const_len, memcmp};

const ROUTE_BENCHMARK: &[u8] = b"/";
const ROUTE_BENCHMARK_LEN: usize = const_len(ROUTE_BENCHMARK);

const TEXT_PLAIN_CONTENT_TYPE: &[u8] = b"Content-Type: text/plain";
const CONTENT_LENGTH: &[u8] = b"Content-Length: ";
const BENCHMARK_BODY: &[u8] = b"This is an HTTP benchmark";
const BENCHMARK_BODY_LEN: usize = const_len(BENCHMARK_BODY);
const BENCHMARK_BODY_SIZE: &[u8] = b"25";

const BENCHMARK_BASE: &[u8] = const_concat_bytes!(
   HTTP_200_OK,
   CRLF,
   SERVER,
   CRLF,
   TEXT_PLAIN_CONTENT_TYPE,
   CRLF,
   CONTENT_LENGTH,
   BENCHMARK_BODY_SIZE,
   CRLF
);

const BENCHMARK_BASE_LEN: usize = const_len(BENCHMARK_BASE);

const BENCHMARK_TEST: &[u8] = b"HTTP/1.1 200 OK\r\nServer: F\r\nContent-Type: text/plain\r\nContent-Length: 25\r\nDate: Thu, 18 Nov 2021 23:15:07 GMT\r\n\r\nHello, World!";
const BENCHMARK_TEST_LEN: usize = const_len(BENCHMARK_TEST);

#[inline]
fn cb(
   method: *const u8,
   method_len: usize,
   path: *const u8,
   path_len: usize,
   response_buffer: *mut u8,
   date_buff: *const u8,
) -> usize {
   unsafe {
      if likely(method_len >= GET_LEN && path_len >= ROUTE_BENCHMARK_LEN) {
         if likely(memcmp(GET.as_ptr(), method, GET_LEN) == 0) {
            if likely(memcmp(ROUTE_BENCHMARK.as_ptr(), path, ROUTE_BENCHMARK_LEN) == 0) {
               core::ptr::copy_nonoverlapping(BENCHMARK_BASE.as_ptr(), response_buffer, BENCHMARK_BASE_LEN);
               core::ptr::copy_nonoverlapping(date_buff, response_buffer.add(BENCHMARK_BASE_LEN), DATE_LEN);
               core::ptr::copy_nonoverlapping(
                  CRLFCRLF.as_ptr(),
                  response_buffer.add(BENCHMARK_BASE_LEN + DATE_LEN),
                  CRLFCRLF_LEN,
               );
               core::ptr::copy_nonoverlapping(
                  BENCHMARK_BODY.as_ptr(),
                  response_buffer.add(BENCHMARK_BASE_LEN + DATE_LEN + CRLFCRLF_LEN),
                  BENCHMARK_BODY_LEN,
               );

               BENCHMARK_BASE_LEN + DATE_LEN + CRLFCRLF_LEN + BENCHMARK_BODY_LEN
            } else {
               core::ptr::copy_nonoverlapping(HTTP_404_NOTFOUND.as_ptr(), response_buffer, HTTP_404_NOTFOUND_LEN);
               HTTP_404_NOTFOUND_LEN
            }
         } else {
            core::ptr::copy_nonoverlapping(HTTP_405_NOTALLOWED.as_ptr(), response_buffer, HTTP_405_NOTALLOWED_LEN);
            HTTP_405_NOTALLOWED_LEN
         }
      } else {
         0
      }
   }
}

pub fn main() {
   faf::epoll::go(3000, cb);
}
