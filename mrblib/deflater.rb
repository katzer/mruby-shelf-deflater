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

# Code from https://github.com/rack/rack/blob/master/lib/rack/deflater.rb

module Shelf
  # This middleware enables compression of http responses.
  #
  # Currently supported compression algorithms:
  #
  #   * gzip
  #   * deflate
  #   * identity (no transformation)
  #
  # The middleware automatically detects when compression is supported
  # and allowed. For example no transformation is made when a cache
  # directive of 'no-transform' is present, or when the response status
  # code is one that doesn't allow an entity body.
  class Deflater
    # Creates Shelf::Deflater middleware.
    #
    # [app] rack app instance
    # [options] hash of deflater options, i.e.
    #           'if' - a lambda enabling / disabling deflation
    #                  e.g use Shelf::Deflater, :if => lambda { |*, body| sum=0; body.each { |i| sum += i.length }; sum > 512 }
    #           'include' - a list of content types that should be compressed
    def initialize(app, options = {})
      @app                = app
      @condition          = options[:if]
      @compressible_types = options[:include]
    end

    def call(env)
      res = @app.call(env)

      should_deflate?(env, *res) ? deflate(env['Accept-Encoding'], *res) : res
    end

    private

    # Turn the uncompressed response into a compressed one.
    #
    # @param [ String ]              encoding The supported compression algos.
    # @param [ Int ]                 status   The response status code.
    # @param [ Hash<String,String> ] headers  The response headers.
    # @param [ Array<String> ]       body     The response body.
    #
    # @return [ Array ]
    def deflate(encoding, status, headers, body)
      if encoding&.include? 'gzip'
        headers['Content-Encoding'] = 'gzip'
        headers.delete('Content-Length')
        [status, headers, body.map! { |s| Zlib.gzip(s) }]
      elsif encoding&.include? 'deflate'
        headers['Content-Encoding'] = 'deflate'
        headers.delete('Content-Length')
        [status, headers, body.map! { |s| Zlib.deflate(s) }]
      else
        [status, headers, body]
      end
    end

    # Test if the middleware should deflate the body based on the response code,
    # http meta data of the response or the middleware config.
    #
    # @param [ Hash<String,String> ] env     The request object.
    # @param [ Int ]                 status  The response status code.
    # @param [ Hash<String,String> ] headers The response headers.
    # @param [ Array<String> ]       body    The response body.
    #
    # @return [ Boolean ]
    def should_deflate?(env, status, headers, body)
      return false if Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status.to_i) ||
                      headers['Cache-Control']&.include?('no-transform') ||
                      headers['Content-Encoding']&.include?('identity')

      return false if @compressible_types&.include?(headers['Content-Type']&.split(';')&.first) == false
      return false if @condition&.call(env, status, headers, body) == false

      true
    end
  end
end
