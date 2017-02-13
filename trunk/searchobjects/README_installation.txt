Instructions for installing searchobjects django website:

1. Setup svn. Search set CSAIL svn in Google and follow instructions.
2. Checkout the repository: svn checkout svn+ssh://login.csail.mit.edu/afs/csail/group/drl/REPOS/video_analysis/trunk/searchobjects
3. Install django 1.4
4. Install postgresql with user postgres. Create a db called postgres as well. (You can create other superusers and dbs if you get errors in next steps.)
4.5 Install pgadmin3, create a server. It might complain of peer authentication failed if you don't have the name of server connection as 'postgres'
5. Ask for database dump from Pramod or Guy, login as postgres user (or other psql user you created), with following cmd: sudo -u postgres -i . Then, import the dump into the db by running this in terminal: psql yourdbname < dumpfile
6. Go to searchobjects/searchobjects/settings.py and change the database settings. If the db/user is postgres, you may have to write 'localhost' in HOST (do this if it complains of Peer authentication failed when doing next steps). 
7. From searchobjects/searchobjects/models.py, delete all the django-given model classes (leave all classes starting with app_)
8. Then from searchobjects directory, run: python manage.py syncdb. Hopefully it doesn't give errors, but if it does, refer Google. :(
9. Go to pgadmin3, and in app_scene database, change the paths to where your video files are (ask for video files to Guy or Pramod if you don't have it)
10. In searchobjects/demo/views.py, change paths(if user-specific) at the 'Global_variables' section on top after imports.
11. Then, run the server from searchobjects directory with: python manage.py runserver, and in the browser, open http://127.0.0.1:8000/ and enjoy.
11.5: One of the errors may be in the line "import cv2", saying it didn't find the library. For that, in ~/.bashrc, add this line: export PYTHONPATH=<OPENCV_INSTALL_DIR>/lib/python2.7/dist-packages:$PYTHONPATH
12. If there are errors, the way I debug is (because I don't have good IDE in backend), I write garbage just below the line I want to debug at, and because DEBUG is set to True, traceback messages are spit out in the template, and we can see the local variables and their values at that particular point when the code hits the garbage line.
13. To debug in frontend, in chrome, open developer console (F12 is the shortcut in most cases). It will show detailed errors in frontend (e.g. javascript), and in network tab, will show the server response.