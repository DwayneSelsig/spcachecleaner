**Project Description**

This script will empty the cache folder and puts a new cache.ini file on all SharePoint servers in the farm.

Sometimes an event with ID 6398 is logged in the Windows Application log. This is usually due to the configuration cache being outdated. So you need to perform some steps on the SharePoint server to force a rebuild of the configuration cache.

**This is a summary of the actions:**
* Stop the “SharePoint 2010 Timer” service.
* Delete all the XML files in the config cache. There are loads of XML files that can be found in the folder “C:\ProgramData\Microsoft\SharePoint\Config\”. Note there seems to only ever be one folder under Config which has a GUID. There are other folders which map onto this folder, but this one seems to be on every environment whereas the other locations may be found in different places on some environments. Therefore deleting the files from this folder should work in all environments.
* Edit the “cache.ini” file in the same folder that contained the XML files, setting the content to “1″ (without the double-quotes). This indicates that all cache settings need to be refreshed. Eventually this value gets automatically updated to another number when the cache is repopulated.
* Start the “SharePoint 2010 Timer” service.

This script executes these steps for you. You need to be a farm administrator to run this script.

**The full description is available at:**
[http://blogs.msdn.com/b/jamesway/archive/2011/05/23/sharepoint-2010-clearing-the-configuration-cache.aspx](http://blogs.msdn.com/b/jamesway/archive/2011/05/23/sharepoint-2010-clearing-the-configuration-cache.aspx)

A lot of work has been done by: Mickey Jervin ([http://mickeyjervin.wordpress.com](http://mickeyjervin.wordpress.com)) and Nick Hobbs ([http://nickhobbs.wordpress.com](http://nickhobbs.wordpress.com))

**This is the event that could be found in the Windows Application log:**

Log Name:      Application

Source:        Microsoft-SharePoint Products-SharePoint Foundation

Date:          2010-05-05 08:49:22

Event ID:      6398

Task Category: Timer

Level:         Critical

Keywords:     

User:          domain\admin

Computer:      MOSS.domain



The Execute method of job definition Microsoft.Office.Server.Administration.ProfileSynchronizationSetupJob (ID <GUID>) threw an exception. More information is included below.

An update conflict has occurred, and you must re-try this action. The object UserProfileApplication Name=User Profile Service Application was updated by domain\admin, in the OWSTIMER (#) process, on machine MOSS.  View the tracing log for more information about the conflict.
