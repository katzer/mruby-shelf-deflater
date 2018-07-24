# MIT License
#
# Copyright (c) Sebastian Katzer 2017
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

def hello_hello_app(code = 200)
  ->(*) { [code, { 'Content-Length' => 11, 'Content-Type' => 'text/html; charset=utf-8' }, ['Hello Hello']] }
end

assert 'Shelf::Deflater' do
  assert_kind_of Class, Shelf::Deflater
end

assert 'Shelf::Deflater#call' do
  assert_true Shelf::Deflater.method_defined? :call
end

assert 'Shelf::Deflater#call', 'deflate' do
  inflator = Shelf::Deflater.new(hello_hello_app)
  status, headers, body = inflator.call('Accept-Encoding' => 'deflate')

  assert_equal 200, status
  assert_include headers, 'Content-Encoding'
  assert_not_include headers, 'Content-Length'
  assert_equal 'deflate', headers['Content-Encoding']
  assert_equal Zlib.deflate('Hello Hello'), body[0]
end

assert 'Shelf::Deflater#call', 'gzip' do
  inflator = Shelf::Deflater.new(hello_hello_app)
  status, headers, body = inflator.call('Accept-Encoding' => 'gzip')

  assert_equal 200, status
  assert_include headers, 'Content-Encoding'
  assert_not_include headers, 'Content-Length'
  assert_equal 'gzip', headers['Content-Encoding']
  assert_equal Zlib.gzip('Hello Hello'), body[0]
end

assert 'Shelf::Deflater#call', 'identity' do
  inflator = Shelf::Deflater.new(hello_hello_app)
  status, headers, body = inflator.call('Accept-Encoding' => 'identity')

  assert_equal 200, status
  assert_include headers, 'Content-Length'
  assert_not_include headers, 'Content-Encoding'
  assert_equal 'Hello Hello', body[0]
end

assert 'Shelf::Deflater#call', 'no-transform' do
  inflator = Shelf::Deflater.new(hello_hello_app)
  status, headers, body = inflator.call('Cache-Control' => 'no-control')

  assert_equal 200, status
  assert_include headers, 'Content-Length'
  assert_not_include headers, 'Content-Encoding'
  assert_equal 'Hello Hello', body[0]
end

assert 'Shelf::Deflater#call', 'unsupported encoding' do
  inflator = Shelf::Deflater.new(hello_hello_app)
  status, headers, body = inflator.call('Accept-Encoding' => 'br')

  assert_equal 200, status
  assert_include headers, 'Content-Length'
  assert_not_include headers, 'Content-Encoding'
  assert_equal 'Hello Hello', body[0]
end

assert 'Shelf::Deflater#call', 'status with no entity body' do
  inflator    = Shelf::Deflater.new(hello_hello_app(100))
  _, headers, = inflator.call('Accept-Encoding' => 'gzip')

  assert_not_include headers, 'Content-Encoding'
end

assert 'Shelf::Deflater#call', 'with include: option' do
  inflator = Shelf::Deflater.new(hello_hello_app, include: 'text/html')
  status, headers, body = inflator.call('Accept-Encoding' => 'gzip')

  assert_equal 200, status
  assert_include headers, 'Content-Encoding'
  assert_not_include headers, 'Content-Length'
  assert_equal 'gzip', headers['Content-Encoding']
  assert_equal Zlib.gzip('Hello Hello'), body[0]

  inflator = Shelf::Deflater.new(hello_hello_app, include: 'text/plain')
  status, headers, body = inflator.call('Accept-Encoding' => 'gzip')

  assert_equal 200, status
  assert_include headers, 'Content-Length'
  assert_not_include headers, 'Content-Encoding'
  assert_equal 'Hello Hello', body[0]
end

assert 'Shelf::Deflater#call', 'with if: option' do
  inflator = Shelf::Deflater.new(hello_hello_app, if: ->(*) { true })
  status, headers, body = inflator.call('Accept-Encoding' => 'gzip')

  assert_equal 200, status
  assert_include headers, 'Content-Encoding'
  assert_not_include headers, 'Content-Length'
  assert_equal 'gzip', headers['Content-Encoding']
  assert_equal Zlib.gzip('Hello Hello'), body[0]

  inflator = Shelf::Deflater.new(hello_hello_app, include: 'text/html', if: ->(*) { false })
  status, headers, body = inflator.call('Accept-Encoding' => 'gzip')

  assert_equal 200, status
  assert_include headers, 'Content-Length'
  assert_not_include headers, 'Content-Encoding'
  assert_equal 'Hello Hello', body[0]
end
