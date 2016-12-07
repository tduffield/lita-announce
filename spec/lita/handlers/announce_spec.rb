require "spec_helper"

describe Lita::Handlers::Announce, lita_handler: true do

  it { is_expected.to route_command("announce list-groups").to(:handle_list_groups) }
  it { is_expected.to route_command("announce add-group name channels").to(:handle_mod_group) }
  it { is_expected.to route_command("announce mod-group name channels").to(:handle_mod_group) }
  it { is_expected.to route_command("announce del-group name").to(:handle_del_group) }
  it { is_expected.to route_command("announce to channel message").to(:handle_announce) }
  it { is_expected.to route_command("announce to group:group1 message").to(:handle_announce) }
  it { is_expected.to route_command("announce to channel1,channel2 message").to(:handle_announce) }
  it { is_expected.to route_command("announce to group:group1,group:group2 messae").to(:handle_announce) }
  it { is_expected.to route_command("announce to group:group1,channel1,group:group2 message").to(:handle_announce) }

  let(:network_group) { %w{abc fox cbs nbc} }
  let(:premium_group) { %w{hbo showtime cinemax} }
  let(:my_favorites) { %w{discover hbo science cbs} }
  let(:all_channels) { [premium_group, network_group, my_favorites].flatten.uniq }

  before do
    all_channels.each { |c| Lita::Room.create_or_update(c) }
    allow(robot.chat_service).to receive(:send_attachment) # This is provided by lita-slack
  end

  describe "list-groups" do
    before { subject.redis.set("group:network", MultiJson.dump({ channels: network_group })) }

    it "returns a list of groups" do
      send_command("announce list-groups")
      expect(replies.last).to eql("\*network\*: #{network_group.map { |c| "##{c}" }.join(", ")}")
    end
  end

  shared_examples_for "group channel modification validation" do
    it "adds group to redis" do
      send_command(command)
      expect(subject.redis.get("group:premium")).to eql(MultiJson.dump({ channels: premium_group }))
      expect(replies.last).to eql(":successful: Announcement group 'premium' updated! Will send messages to #{premium_group.map { |c| "##{c}" }.join(", ")}")
    end

    context "when group name is invalid" do
      let(:group) { "premium:movies" }

      it "returns an error message" do
        send_command(command)
        expect(replies.last).to eql(":failed: '#{group}' is not a valid name. Please use only letters, numbers, and underscores.")
      end
    end

    context "when a channel provided does not exist" do
      let(:channels) { premium_group.push("skinemax").join(",") }

      it "returns an error message" do
        send_command(command)
        expect(replies.last).to eql(":failed: Can not create '#{group}': the #skinemax channel does not exist.")
      end
    end

    context "when the channel list is formatted incorrectly" do
      let(:channels) { premium_group.join(" ") }

      it "returns an error message" do
        send_command(command)
        expect(replies.last).to eql(":failed: Please provide channels as a comma-separated list with no spaces.")
      end
    end
  end

  describe "add-group" do
    let(:group) { "premium" }
    let(:channels) { premium_group.join(",") }
    let(:command) { "announce add-group #{group} #{channels}" }

    it_behaves_like "group channel modification validation"
  end

  describe "mod-group" do
    let(:group) { "premium" }
    let(:channels) { premium_group.push("starz").join(",") }
    let(:command) { "announce mod-group #{group} #{channels}" }

    before do
      subject.redis.set("group:premium", MultiJson.dump({ channels: premium_group }))
      Lita::Room.create_or_update("starz")
    end

    it_behaves_like "group channel modification validation"
  end

  describe "del-group" do
    let(:group) { "premium" }
    let(:command) { "announce del-group #{group}" }

    before { subject.redis.set("group:premium", MultiJson.dump({ channels: premium_group })) }

    it "deletes group from redis" do
      send_command(command)
      expect(subject.redis.get("group:#{group}")).to be_nil
      expect(replies.last).to eql(":successful: Announcement group '#{group}' deleted.")
    end

    context "when group does not exist" do
      let(:group) { "static-only" }

      it "returns error message" do
        send_command(command)
        expect(replies.last).to eql(":failed: Can not delete '#{group}': does not exist.")
      end
    end
  end

  describe "making an announcement" do
    let(:message) { "Everyone just watches Netflix anyways" }
    let(:command) { "announce to #{targets} #{message}" }
    let(:payload) do
      {
        author: user.name,
        channels: expected_channels.uniq,
        text: message,
        timestamp: DateTime.now.to_time.to_i,
      }
    end

    before do
      subject.redis.set("group:premium", MultiJson.dump({ channels: premium_group }))
      subject.redis.set("group:network", MultiJson.dump({ channels: network_group }))
      subject.redis.set("group:my_favorites", MultiJson.dump({ channels: my_favorites }))
    end

    shared_examples_for "an announcement" do
      let(:expected_message) { "#{payload[:text]} - #{payload[:author]}" }
      it "writes the message to redis" do
        send_command(command)
        expect(subject.redis.lpop("announcements")).to eql(payload.to_json)
      end

      it "sends message" do
        payload[:channels].each do |channel|
          expect(robot).to receive(:join).with(Lita::Room.fuzzy_find(channel))
        end
        send_command(command)
        expect(replies.length).to eql(payload[:channels].length)
        expect(replies.last).to eql(expected_message)
      end
    end

    context "to a single channel" do
      let(:targets) { "cbs" }
      let(:expected_channels) { %w{cbs} }

      it_behaves_like "an announcement"
    end

    context "to multiple channels" do
      let(:targets) { "cbs,hbo" }
      let(:expected_channels) { %w{cbs hbo} }

      it_behaves_like "an announcement"
    end

    context "to a single group" do
      let(:targets) { "group:premium" }
      let(:expected_channels) { premium_group }

      it_behaves_like "an announcement"
    end

    context "to multiple groups" do
      let(:targets) { "group:premium,group:network,group:my_favorites" }
      let(:expected_channels) { all_channels }

      it_behaves_like "an announcement"
    end

    context "to a combination of groups and channels" do
      let(:targets) { "group:premium,fox,cbs" }
      let(:expected_channels) { premium_group.concat(%w{fox cbs}) }

      it_behaves_like "an announcement"
    end
  end
end
