//
//  main.cpp
//  rtimproc-server
//
//  Created by Mikhail Volkov on 4/17/14.
//  Copyright (c) 2014 Mikhail Volkov. All rights reserved.
//

#include <iostream>
#include <iomanip>
#include <sstream>
#include <cstring>      // Needed for memset
#include <sys/socket.h> // Needed for the socket functions
#include <netdb.h>      // Needed for the socket functions
#include <unistd.h>

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include "rtvproc_types.h"
#include "rtvproc_msg.h"
#include "RTVideoProcessing.h"

using std::cout;
using std::cerr;
using std::endl;

//////////////////////////////////////////////////////////////////////////////
// variables

bool feat_mode = false;
bool quiet_mode = false;
int webcam_no = 0;

char* host;
char* port;
int socket_hnd; // The socket descriptor

struct addrinfo host_info;       // The struct that getaddrinfo() fills up with data.
struct addrinfo *host_info_list; // Pointer to the to the linked list of host_info's.

//char incomming_data_buffer[BUFSIZ];
ssize_t bytes_sent;
ssize_t bytes_received;
std::stringstream iss;
message_t tx_message;
message_t rx_message;

RTVideoProcessingStream* video_server = NULL;
VQ_struct VQ;

std::string desc_type = "SURF";

rtimproc_src_mode src_mode = RTIMPROC_SRC_CAPTURE;

std::string vq_filename;
std::string video_filename;

cv::VideoCapture cap;
cv::Mat src_image;
cv::Mat tx_image;

FrameDesc frame_struct;
unsigned int frame_index;

unsigned int tx_width;
unsigned int tx_height;
unsigned int tx_frame_size[2];
unsigned int hist_size;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// setup client
int setup()
{
  int status = 1;
  
  //============================================================================
  cout << "Initializing connection..." << endl;
  
  // The MAN page of getaddrinfo() states "All  the other fields in the structure pointed
  // to by hints must contain either 0 or a null pointer, as appropriate." When a struct
  // is created in c++, it will be given a block of memory. This memory is not nessesary
  // empty. Therefor we use the memset function to make sure all fields are NULL.
  memset(&host_info, 0, sizeof host_info);
  
  host_info.ai_family = AF_UNSPEC;     // IP version not specified. Can be both.
  host_info.ai_socktype = SOCK_STREAM; // Use SOCK_STREAM for TCP or SOCK_DGRAM for UDP.
  host_info.ai_flags = AI_PASSIVE;     // IP Wildcard
  
  // Now fill up the linked list of host_info structs with google's address information.
  int getaddrinfo_status = getaddrinfo(NULL, port, &host_info, &host_info_list);
  // getaddrinfo returns 0 on succes, or some other value when an error occured.
  // (translated into human readable text by the gai_gai_strerror function).
  if (getaddrinfo_status != 0)
  {
    cerr << "getaddrinfo error: " << gai_strerror(getaddrinfo_status) << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  cout << "Creating socket..." << endl;
  
  socket_hnd = socket(host_info_list->ai_family,
                      host_info_list->ai_socktype,
                      host_info_list->ai_protocol);
  
  if (socket_hnd == -1)
  {
    cerr << "socket error" << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  cout << "Binding socket..." << endl;
  
  // we use to make the setsockopt() function to make sure the port is not in use
  // by a previous execution of our code. (see man page for more information)
  int option_value = 1;
  int setsockopt_status = setsockopt(socket_hnd, SOL_SOCKET, SO_REUSEADDR, &option_value, sizeof(int));
  if (setsockopt_status != 0)
  {
    cerr << "setsockopt error" << endl;
    status = -1;
  }
  
  int bind_status  = ::bind(socket_hnd, host_info_list->ai_addr, host_info_list->ai_addrlen);
  if (bind_status == -1)
  {
    cerr << "bind error" << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  cout << "Listening for connections..." << endl;
  
  int listen_status  = listen(socket_hnd, 5);
  if (listen_status == -1)
  {
    cerr << "listen error" << endl;
    status = -1;
  }
    
  struct sockaddr_storage their_addr;
  socklen_t addr_size = sizeof(their_addr);
  socket_hnd = accept(socket_hnd, (struct sockaddr *)&their_addr, &addr_size);
  if (socket_hnd == -1)
  {
    cerr << "accept error" << endl;
    status = -1;
  }
  else
    cout << "Connection accepted. Using new socket_hnd: " << socket_hnd << endl;
  
  //----------------------------------------------------------------------------
  cout << "Waiting for session request..." << endl;
  
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_TX_BEGIN);
  
  // send ack
  SendMessage(socket_hnd, RTIMPROC_ACK);
  
  cout << "Session open!" << endl;
  
  //----------------------------------------------------------------------------
  cout << "Initializing source..." << endl;
  
  cout << "loading vq file: " << vq_filename << endl;
  VQ = LoadVQ(vq_filename);
  cout << "loading video: " << video_filename << endl;
  switch (src_mode)
  {
    case RTIMPROC_SRC_CAPTURE:
      video_server = new RTVideoProcessingStream(VQ.mat, "", desc_type, webcam_no);
      break;
    case RTIMPROC_SRC_VIDEO:
      video_server = new RTVideoProcessingStream(VQ.mat, video_filename, desc_type);
      break;
  }
  tx_width = video_server->get_frame_width();
  tx_height = video_server->get_frame_height();
  
  cout << "Session open!" << endl;
  
  //============================================================================
  cout << "Initializing session variables..." << endl;
  
  //----------------------------------------------------------------------------
  // wait for frame size request
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_FRAME_SZ);
  
  // send frame size
  tx_frame_size[0] = tx_width;
  tx_frame_size[1] = tx_height;
  cout << "frame size = " << tx_frame_size << endl;
  bytes_sent = send(socket_hnd, tx_frame_size, 2*sizeof(unsigned int), 0);
  if (bytes_sent == 0)
  {
    cerr << "send error" << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  // wait for hist size request
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_HIST_SZ);
  
  // send hist size
  hist_size = (unsigned int)VQ.descriptor_dim;
  cout << "hist size = " << hist_size << endl;
  bytes_sent = send(socket_hnd, &hist_size, sizeof(unsigned int), 0);
  if (bytes_sent == 0)
  {
    cerr << "send error" << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  
  return status;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// send frame
int send_frame()
{
  
  int status = 1;
  
  cout << "--------------------" << endl;
  
  //----------------------------------------------------------------------------
  // get next frame from video server
  frame_struct = video_server->process_next_frame();
  frame_index = video_server->get_frame_idx();
  src_image = frame_struct.img.clone();
  
  //============================================================================
  // send frame index
  
  cout << "frame = " << frame_index << endl;
  
  // wait for frame index request
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_FRAME_IDX);
  
  // send frame index
  bytes_sent = send(socket_hnd, &frame_index, sizeof(unsigned int), 0);
  //cout << "bytes sent = " << bytes_sent << endl;
  if (bytes_sent == 0)
  {
    cerr << "send error" << endl;
    status = -1;
  }
  
  //============================================================================
  // send frame
  
  // wait for frame request
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_FRAME_RQ);
  
  // reset session:
  // not using any more since rx_message is inner scope
  //if (rx_message == RTIMPROC_TX_RESET)
  //  break;
  
  uchar* frame_data;
  unsigned long frame_size;
  
  // resize source image
  cv::resize(src_image, tx_image, cv::Size(tx_width,tx_height));
  
  // display image
  //imshow("sending image", tx_image);
  //cv::waitKey(33);
  
  // prepare data
  frame_data = tx_image.data;
  frame_size = tx_image.total()*tx_image.elemSize();
  
  cout << "Sending frame: " << tx_image.rows << "x" << tx_image.cols << " = " << frame_size << endl;
  
  // send data
  bytes_sent = send(socket_hnd, frame_data, frame_size, 0);
  //cout << "bytes sent = " << bytes_sent << endl;
  if (bytes_sent == 0)
  {
    cerr << "send error" << endl;
    status = -1;
  }
  
  // wait for frame rx response
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_FRAME_RX);
  
  // send ack
  SendMessage(socket_hnd, RTIMPROC_ACK);
  
  //============================================================================
  // send hist
  
  // wait for hist request
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_HIST_RQ);
  
  cout << "Sending hist..." << endl;
  
  // send data
  unsigned int* hist_data = &frame_struct.hist[0];
  bytes_sent = send(socket_hnd, hist_data, hist_size*sizeof(unsigned int), 0);
  cout << "bytes sent = " << bytes_sent << endl;
  if (bytes_sent == 0)
  {
    cerr << "send error" << endl;
    status = -1;
  }
  
  //cout << hist_size << " hist values sent" << endl;
  //for (int i = 0; i < frame_struct.hist.size(); i++)
  //  cout << frame_struct.hist[i] << ',';
  //cout << ".." << endl;
  
  // wait for hist rx response
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_HIST_RX);
  
  // send ack
  SendMessage(socket_hnd, RTIMPROC_ACK);
  
  //----------------------------------------------------------------------------
  // send features
  
  if (feat_mode)
  {
    // wait for size request
    WaitForMessage(socket_hnd, rx_message, RTIMPROC_FEAT_SZ);

    // send feat size
    unsigned int feat_size = frame_struct.num_features;
    cout << "feat size = " << feat_size << endl;
    bytes_sent = send(socket_hnd, &feat_size, sizeof(unsigned int), 0);
    if (bytes_sent == 0)
      cerr << "send error" << endl;

    // wait for feat request
    WaitForMessage(socket_hnd, rx_message, RTIMPROC_FEAT_RQ);

    cout << "Sending features..." << endl;
    
    // send data
    unsigned int* feat_xy_data = &frame_struct.feat_xy[0];
    bytes_sent = send(socket_hnd, feat_xy_data, 2*feat_size*sizeof(unsigned int), 0);
    //cout << "bytes sent = " << bytes_sent << endl;
    if (bytes_sent == 0)
      cerr << "send error" << endl;

    // wait for feat rx response
    WaitForMessage(socket_hnd, rx_message, RTIMPROC_FEAT_RX);

    // send ack
    SendMessage(socket_hnd, RTIMPROC_ACK);
  }
  
  //----------------------------------------------------------------------------
  
  return status;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{ 
  // parse args
  std::stringstream usage;
  usage << "usage: ./rtvproc_server";
  usage << " port";
  usage << " [-vq vq_filename]";
  usage << " [-i video_filename]";
  usage << " [-w webcam_no]";
  usage << " [--feat]";
  usage << " [--quiet]";
  
  // required args
  if (argc < 2)
  {
    cerr << usage.str() << endl;
    exit(-1);
  }
  port = argv[1];

  // optional args
  for (int i = 2; i < argc; i++)
  {
    if (i < argc)
    {
      if (std::string(argv[i]) == "-vq")
      {
        vq_filename = std::string(argv[i+1]);
        src_mode = RTIMPROC_SRC_CAPTURE;
        i++;
      }
      else if (std::string(argv[i]) == "-i")
      {
        video_filename = std::string(argv[i+1]);
        src_mode = RTIMPROC_SRC_VIDEO;
        i++;
      }
      else if (std::string(argv[i]) == "-w")
      {
        webcam_no = atoi(argv[i+1]);
        i++;
      }
      else if (std::string(argv[i]) == "--feat")
      {
        feat_mode = true;
      }
      else if (std::string(argv[i]) == "--quiet")
      {
        quiet_mode = true;
      }
    }
    else
    {
      cerr << usage.str() << endl;
      exit(-1);
    }
  }

  if (quiet_mode)
  {
    // redirect output streams to null_stream
    std::cout.rdbuf(std::ostream(0).flush().rdbuf());
    std::cerr.rdbuf(std::ostream(0).flush().rdbuf());
  }
  
  // server persistance
  while(1)
  {
    
    //----------------------------------------------------------------------------
    // setup
    int setup_status = setup();
    if (setup_status < 0)
    {
      cerr << "setup error" << endl;
      exit(-1);
    }
    
    //----------------------------------------------------------------------------
    // send frames
    cout << "----------------------------------------" << endl;
    cout << "Sending frames:" << endl;
    int frame_status;
    while(1)
    {
      
      frame_status = send_frame();
      
      if (frame_status < 0)
      {
        cerr << "frame error" << endl;
        //exit(-1);
        continue;
      }
      
    }
    
    //////////////////////////////////////////////////////////////////////////////
    cout << "Restarting session..." << endl;
    
    cap.release();
    
    freeaddrinfo(host_info_list);
    close(socket_hnd);
    
  }
  
  return 0;
  
}

