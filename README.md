# lita-announce

Quick and easy way to share content with multiple channels.

## Installation

Add lita-announce to your Lita instance's Gemfile:

``` ruby
gem "lita-announce"
```

## Usage

    @lita announce to <channels> <content>
    @lita announce to <groups> <content>
    @lita announce list-groups
    @lita announce add-group <name> <channels>
    @lita announce mod-group <name> <channels>
    @lita announce del-group <name>

### Managing Groups

#### list-groups

    @lita announce list-groups
    Group1: #channel1, #channel2, #channel3
    Group2: #channel1, #channel4

#### add-group
Each group must have a unique name that contains only letters, numbers, and underscores.

    @lita announce add-group devs foo-dev,bar-dev,baz-dev

#### mod-group
Modify the list of channels in a group. Must provide the full list.

    @lita announce mod-group devs foo-dev,bar-dev,baz-dev,super-dev

#### del-group
Delete a group.

    @lita announce del-group devs

### Making Announcements

#### Send a message to multiple channels

    @lita announce to general,random Hey everyone! All hands is starting in five minutes! Join us in #all-hands-meeting. :smile:

### Share a message with a pre-configured group of channels

    @lita announce add-group devs foo-dev,bar-dev,baz-dev

    @lita announce to group:devs Don't forget to turn in your TPS reports!

### Share a link with several pre-configured groups of channels

    @lita announce add-group devs foo-dev,bar-dev,baz-dev
    @lita announce add-group foo-announcements foo-dev,foo-announce,foo-discuss

    @lita announce to group:foo-announcements,group:devs Hey everyone! Thanks for your combined effort to get foo out the door!

And don't worry! Messages will only get send to channels once, even if they are part of multiple groups!

### Share a link with a combination of groups and channels

    @lita announce add-group devs foo-dev,bar-dev,baz-dev

    @lita announce to group:devs,general Hey everyone! Make sure that you get your TPS reports in on time this week.
