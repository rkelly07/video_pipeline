# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#     * Rearrange models' order
#     * Make sure each model has one field with primary_key=True
# Feel free to rename the models, but don't rename db_table values or field names.
#
# Also note: You'll have to insert the output of 'django-admin.py sqlcustom [appname]'
# into your database.

from django.db import models

class AppLabel(models.Model):
    id = models.IntegerField(primary_key=True)
    title = models.CharField(max_length=255)
    time_added = models.DateTimeField()
    time_updated = models.DateTimeField()
    current_version = models.IntegerField()
    weights = models.TextField(blank=True) # This field type is a guess.
    thresholds = models.TextField(blank=True) # This field type is a guess.
    class Meta:
        db_table = u'app_label'

class AppTag(models.Model):
    id = models.IntegerField(primary_key=True)
    label_id = models.IntegerField()
    frame = models.IntegerField()
    stream = models.IntegerField(null=True, blank=True)
    class Meta:
        db_table = u'app_tag'

class AppScene(models.Model):
    id = models.IntegerField(primary_key=True)
    path = models.CharField(max_length=4096)
    frames = models.IntegerField()
    frame_rate = models.IntegerField()
    width = models.IntegerField()
    height = models.IntegerField()
    time_taken = models.DateTimeField()
    time_added = models.DateTimeField()
    thumbnail = models.CharField(max_length=200)
    timestamp = models.CharField(max_length=128, blank=True)
    class Meta:
        db_table = u'app_scene'

class AppUserselection(models.Model):
    id = models.IntegerField(primary_key=True)
    frame = models.IntegerField()
    x1 = models.IntegerField()
    x2 = models.IntegerField()
    y1 = models.IntegerField()
    y2 = models.IntegerField()
    time_added = models.DateTimeField()
    processed = models.BooleanField()
    label = models.ForeignKey(AppLabel)
    scene = models.ForeignKey(AppScene)
    class Meta:
        db_table = u'app_userselection'

class AppRegion(models.Model):
    id = models.IntegerField(primary_key=True)
    frame = models.IntegerField()
    x1 = models.IntegerField()
    x2 = models.IntegerField()
    y1 = models.IntegerField()
    y2 = models.IntegerField()
    features = models.TextField(blank=True) # This field type is a guess.
    features_time = models.DateTimeField(null=True, blank=True)
    label_version = models.IntegerField()
    label = models.ForeignKey(AppLabel, null=True, blank=True)
    scene = models.ForeignKey(AppScene, null=True, blank=True)
    confidence = models.FloatField(null=True, blank=True)
    class Meta:
        db_table = u'app_region'
        

class AppSyntheticRegion(models.Model):
    id = models.IntegerField(primary_key=True)
    frame = models.IntegerField()
    x1 = models.IntegerField(blank=True, null=True)
    x2 = models.IntegerField(blank=True, null=True)
    y1 = models.IntegerField(blank=True, null=True)
    y2 = models.IntegerField(blank=True, null=True)
    class_id = models.IntegerField(blank=True, null=True)
    scene = models.ForeignKey(AppScene, blank=True, null=True)
    confidence = models.FloatField(blank=True, null=True)
    importance = models.FloatField(blank=True, null=True)
    class Meta:
        managed = False
        db_table = 'app_synthetic_region'


class AppClassMapping(models.Model):
    class_id = models.IntegerField(primary_key=True)
    class_name = models.TextField(blank=True)
    class Meta:
        db_table = u'app_class_mapping'

class AppSyntheticObjectClasses(models.Model):
    class_id = models.IntegerField()
    class_name = models.TextField()
    id = models.IntegerField(primary_key=True)
    class Meta:
        managed = False
        db_table = 'app_synthetic_object_classes'



class VideoDocument(models.Model):
    #docfile = models.FileField(upload_to='video_uploads/%Y-%m-%d')
    docfile = models.FileField(upload_to='file_uploads/videos')

class GPSDocument(models.Model):
    docfile = models.FileField(upload_to='file_uploads/gps_files')


class AppTextDetection(models.Model):
    frame = models.IntegerField(blank=True, null=True)
    scene = models.ForeignKey(AppScene, db_column='scene_id', blank=True, null=True)
    x1 = models.IntegerField(blank=True, null=True)
    x2 = models.IntegerField(blank=True, null=True)
    y1 = models.IntegerField(blank=True, null=True)
    y2 = models.IntegerField(blank=True, null=True)
    detected_text = models.TextField(blank=True)
    confidence = models.FloatField(blank=True, null=True)
    id = models.IntegerField(primary_key=True)
    class Meta:
        managed = False
        db_table = 'app_text_detection'

class AppCoreset(models.Model):
    scene = models.ForeignKey('AppScene', blank=True, null=True)
    coreset_tree_path = models.TextField(blank=True)
    coreset_results_path = models.TextField(blank=True)
    simple_coreset_path = models.TextField(blank=True)
    id = models.IntegerField(primary_key=True)
    class Meta:
        managed = False
        db_table = 'app_coreset'
