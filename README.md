# PimMeNow

PimMeNow is a small PowerShell GUI Tool that handles Azure AD Priveleged Identity Management (PIM) connects to multiple tenants.

You configure your PIM profiles with:

* Profile Name
* User Account
* Tenant ID
* PIM Role
* Duration
* Microsoft Edge Profile Number

PimMeNow will then start a GUI and give you the choice to connect to one of your PIM profiles. Justification Reasons will be saved to a txt file and offered to you via autocomplete in your next session. 

After you have authenticated against the appropriate AAD, the related Edge profile for that PIM profile will start.

It will also start a counter that counts the time left for your PIM session. 

More information here on my blog: https://emptydc.com/2020/03/11/pim-me-now-!

Written by: Jan Geisbauer | Twitter: @janvonkirchheim | Blog: https://emptydc.com | Podcast: https://hairlessinthecloud.com

