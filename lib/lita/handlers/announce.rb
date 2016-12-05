#
# Copyright:: Copyright 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "time"

module Lita
  module Handlers
    class Announce < Handler

      config :announcements_to_keep, default: 10

      route(
        /^announce\s+list-groups/i,
        :handle_list_groups,
        command: true,
        help: {
          "announce list-groups" => "list-groups",
        }
      )

      route(
        /^announce\s+add-group\s+(.+)/i,
        :handle_mod_group,
        command: true,
        help: {
          "announce add-group" => "add-group <name> <channels>",
        }
      )

      route(
        /^announce\s+mod-group\s+(.+)/i,
        :handle_mod_group,
        command: true,
        help: {
          "announce mod-group" => "mod-group <name> <channels>",
        }
      )

      route(
        /^announce\s+del-group\s+(.+)/i,
        :handle_del_group,
        command: true,
        help: {
          "announce del-group" => "del-group <name>",
        }
      )

      route(
        /^announce\s+to\s+(.+)/i,
        :handle_announce,
        command: true,
        help: {
          "announce" => "announce to <groups and channels> <message>",
        }
      )

      def handle_list_groups(response)
        results = []
        redis.scan_each do |key|
          if key =~ /^group:(\w+)$/
            channels = MultiJson.load(redis.get(key))["channels"]
            results << "*#{$1}*: #{channels.map { |c| "\##{c}" }.join(", ")}"
          end
        end
        response.reply(results.join("\n"))
      end

      def handle_mod_group(response)
        group    = response.args[1]
        channels = response.args[2]

        unless group =~ /^\w+$/
          response.reply(":failed: '#{group}' is not a valid name. Please use only letters, numbers, and underscores.")
          return
        end

        unless response.args[3].nil?
          response.reply(":failed: Please provide channels as a comma-separated list with no spaces.")
          return
        end

        channel_array = channels.split(",").map { |c| c.gsub(/^\#/, "") }

        all_channels_exist = true
        channel_array.each do |c|
          if Lita::Room.fuzzy_find(c).nil?
            response.reply(":failed: Can not create '#{group}': the \##{c} channel does not exist.")
            all_channels_exist = false
          end
        end
        return unless all_channels_exist

        redis.set("group:#{group}", MultiJson.dump({ channels: channel_array }))
        response.reply(":successful: Announcement group '#{group}' updated! Will send messages to #{channel_array.map { |c| "\##{c}" }.join(", ")}")
      end

      def handle_del_group(response)
        group = response.args[1]

        if redis.get("group:#{group}").nil?
          response.reply(":failed: Can not delete '#{group}': does not exist.")
          return
        end

        redis.del("group:#{group}")
        response.reply(":successful: Announcement group '#{group}' deleted.")
      end

      def handle_announce(response)
        channels = parse_channels(response.args[1])
        message  = response.args[2..-1].join(" ")

        return if channels.nil?

        payload = {
          author: response.user.name,
          channels: channels.uniq,
          text: message,
          timestamp: DateTime.now.to_time.to_i,
        }

        save_announcement(payload)
        make_announcement_to_channels(payload)
      end

      def parse_channels(targets)
        channels = []
        targets.split(",").each do |target|
          c = parse_target(target)

          if c.nil?
            response.reply(":failed: Could not send message: the group '#{target}' could not be found.")
            return nil
          else
            channels.concat(c)
          end
        end
        channels
      end

      def save_announcement(payload)
        redis.lpush("announcements", MultiJson.dump(payload))
        redis.ltrim("announcements", 0, config.announcements_to_keep - 1)
      end

      def make_announcement_to_channels(payload)
        payload[:channels].each do |c|
          channel = Lita::Source.new(room: Lita::Room.fuzzy_find(c))
          robot.send_message(channel, "#{payload[:text]} - #{payload[:author]}")
        end
      end

      def parse_target(target)
        if target =~ /^group:(\w+)$/
          group = redis.get(target)
          return nil if group.nil?
          MultiJson.load(group)["channels"]
        else
          [target]
        end
      end

      Lita.register_handler(self)
    end
  end
end
