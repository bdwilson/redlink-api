Honeywell Redlink GET/POST API
=======
<br>
This is a basic GET/POST implementation of [Honeywell's Redlink/Wireless
Thermostat
interface](https://rs.alarmnet.com/TotalConnectComfort/ws/MobileV2.asmx). This
is a basic Login, get Thermostat info script. More could be done using the
functions referenced above. This was done to extract Indoor temp/Humidity to
keep track of it using SaaS providers like Thingspeak. This script prints out
your location name(s), current temp, setpoint and *assumed* status (since
there's no way to really tell if the system is actually on or not; no idea why
Honeywell doesn't report this!). 

*Thanks to [Aaron Gotwalt](https://github.com/gotwalt/redlink) for his Ruby
implementation of this to get me going on the AppID. I couldn't get his script
to work, so I made this.*

Requirements
------------
- Honeywell Wireless Thermostat or Redlink Internet Gateway
- [My Total Connect Comfort Account](https://rs.alarmnet.com/TotalConnectComfort/ws/MobileV2.asmx)
- Valid AppID - for example: 5o950s6r-sp89-4o84-9046-4n0009q9oq3o Note, this is
  not an actual AppID[.](http://www.rot13.com)
- Perl Modules: LWP::Simple XML::TreePP HTTP::Request::Common Data::Dumper Config::Simple

I recommend installing [cpanminus](https://github.com/miyagawa/cpanminus) and
installing them that way.
<pre>
sudo apt-get install curl
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
</pre>

Then install the modules..
<pre>
sudo cpanm LWP::Simple XML::TreePP HTTP::Request::Common Data::Dumper Config::Simple
</pre>

Installation
--------------------
1. Install Perl modules.
2. Obtain a valid AppID (Hint: they use a static key in their iOS app; Charles proxy w/ SSL support will help you here)
3. Create a config file in ~/.redlink.ini that looks like so (you need your
valid appid though):
<pre>
[user]
username=email@address.com
password=password
appid=5o950s6r-sp89-4o84-9046-4n0009q9oq3o
</pre>
4. Running the script should list your location name(s), current temp, setpoint
temp and if your system is running.
5. You can use the Alarmnet link above to see other functions that you can call
to actually make changes, but I haven't implemented those. 

Bugs/Contact Info
-----------------
Bug me on Twitter at [@brianwilson](http://twitter.com/brianwilson) or email me [here](http://cronological.com/comment.php?ref=bubba).


