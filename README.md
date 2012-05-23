WinCDP
======

## Cisco Discovery Protocol Client for Windows
Chris Hall 2010-2012

![WinCDP is a Windows Cisco Discovery Protocol Client](https://sites.google.com/site/chall32/general/WinCDP.png)

### What is CDP?
Cisco Discovery Protocol (CDP) is a proprietary Data Link Layer network protocol developed by Cisco Systems. It is used to share information about other directly connected Cisco equipment, such as the operating system version and IP address.

CDP packets will give you a lot of valuable information if you can capture them. They will give you all the details of the Cisco switch your on and the port on that switch you're connected to.  Of course as CDP is proprietary, you typically won't find it anywhere else other than on Cisco networking kit.

### Why?
Lets face it.  We have all been there: "where does this network cable / uplink / port go?"

Until now, it has been a matter of looking up cable numbers in databases, fiddling about in the back of server and network racks or worst case - sending the smallest guy down to play hunchback in the windy air conditioned gloom under the floor.

There must be a better way to tell where a network cable goes to without having to go to all that trouble every time...

VMware ESX has CDP support built in. Why not also have CDP support in Windows?


***See the [changelog] for what's new in the most recent release.***


[changelog]: https://github.com/chall32/WinCDP/blob/master/ChangeLog.txt
