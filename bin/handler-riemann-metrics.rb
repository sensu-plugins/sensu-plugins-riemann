#! /usr/bin/env ruby
##  encoding: UTF-8
##   riemann
##
## DESCRIPTION:
##
#  Sends metrics data to a Riemann server.
#
## OUTPUT:
##   metric data
##
## PLATFORMS:
##   All
##
## DEPENDENCIES:
##   gem: sensu-plugin
##   gem: riemann-client
##
## LICENSE:
##   James Turnbull <james@lovedthanlost.net>
##   Released under the same terms as Sensu (the MIT license); see LICENSE
##   for details.
##

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require 'riemann/client'

class Riemann < Sensu::Handler
  # override filters from Sensu::Handler. not appropriate for metric handlers
  def filter; end

  def event_state
    case @event['check']['status']
    when 0
      'ok'
    when 1
      'warning'
    when 2
      'critical'
    else
      'unknown'
    end
  end

  def handle
    riemann_host = settings['riemann']['riemann_host']
    riemann_port = settings['riemann']['riemann_port']
    metrics = @event['check']['output']
    check_name = @event['check']['name']
    client_name = @event['client']['name']
    client = Riemann::Client.new host: riemann_host, port: riemann_port, timeout: 5

    begin
      metrics.split("\n").each do |output_line|
        (metric_name, metric_value, epoch_time) = output_line.split("\t")
        client << {
          host: client_name,
          service: check_name,
          tags: ['sensu'],
          time: epoch_time,
          state: event_state,
          description: metric_name,
          metric: metric_value
        }
      end
    end
  end
end
