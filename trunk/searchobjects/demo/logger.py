import os

class SearchObjectsLogger:
    video_filepath = ""
    action = "" #eg. upload, retrieve, etc.
    sub_action = ""
    time_start = ""
    time_end = ""
    time_taken = ""
    status = ""
    log_line = None
    
    def __init__(self,log_file_path):
        if os.path.isfile(log_file_path):
            self.logfile = log_file_path
        else:
            raise Exception('Log file',log_file_path, 'does not exist')
    
    def set_video_filepath(self, path):
        self.video_filepath = path
        
    def set_action(self, action):
        self.action = action
        
    def set_sub_action(self, sub_action):
        self.sub_action = sub_action
        
    def set_time_start(self, time_start):
        self.time_start = str(time_start)
            
    def set_time_end(self, time):
        self.time_end = str(time)
            
    def set_time_taken(self,time):
        self.time_taken = str(time)   

    def set_status(self, status):
        self.status = status


    def add_log_line(self, video_filepath, action, sub_action, time_start, time_end, time_taken):
        if self.time_start != "" and self.time_end != "" and self.time_taken == "":
            self.time_taken=str(float(self.time_end) - float(self.time_start))
        log_line = video_filepath+", "+action+", "+sub_action+", "+time_start+", "+time_end+", "+time_taken+"\n"
        if self.log_line != None:
            log_line =self.log_line + log_line
            
    def add_log_line(self):
        if self.time_start != "" and self.time_end != "" and self.time_taken == "":
            self.time_taken=str(float(self.time_end) - float(self.time_start))
        log_line = self.video_filepath+", "+self.action+", "+self.sub_action+", "+self.time_start+", "+self.time_end+", "+self.time_taken+", "+self.status+"\n"
        if self.log_line != None:
            log_line =self.log_line + log_line        
        self.log_line = log_line
    

    def log_lines_to_file(self):
        if self.log_line != None:
            with open(self.logfile, "a") as logfile:
                logfile.write(self.log_line)
                logfile.close()
                self.log_line = None
    
    def log_line_to_file(self, line):
        with open(self.logfile, "a") as logfile:
            logfile.write(line) 
            logfile.close()
    
    def log_to_file(self):
        if len(self.video_filepath.strip()) > 0: #log only if there's video file path
            with open(self.logfile, "a") as logfile:
                line_to_append = ""
                if self.time_start != "" and self.time_end != "" and self.time_taken == "":
                    self.time_taken=str(float(self.time_end) - float(self.time_start))
                
                line_to_append = "\n" + self.video_filepath + ", " + self.action + ", " + self.sub_action \
                + ", " + self.time_start + ", "+self.time_end + ", "+self.time_taken + ", "+self.status
                
                logfile.write(line_to_append)        
                logfile.close()
        else:
            raise Exception("Video file path must be there to log.")