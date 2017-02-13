from django.conf.urls import patterns, include, url
from django.conf import settings
from django.conf.urls.static import static
#from django.views.generic.simple import redirect_to
from django.conf.urls import patterns
from django.views.generic import RedirectView

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('',
    url(r'^$', 'demo.views.index'),
    url(r'^fetch_pics/$', 'demo.views.fetch_pics'),
    url(r'^upload_video/$', 'demo.views.upload_video'),
    url(r'^upload_gps_file/$', 'demo.views.upload_gps_file'),
    url(r'^summarize_video/$', 'demo.views.summarize_video'),
    #url(r'^media/(?P<path>.*)$','django.views.static.serve',{'document_root': settings.MEDIA_ROOT, }),
    # Examples:
    # url(r'^$', 'mysite.views.home', name='home'),
    # url(r'^mysite/', include('mysite.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    # url(r'^admin/', include(admin.site.urls)),
)+ static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)


