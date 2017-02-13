//
//  main.cpp
//  rtimproc-client
//
//  Created by Mikhail Volkov on 4/17/14.
//  Copyright (c) 2014 Mikhail Volkov. All rights reserved.
//

#include <iostream>
#include <iomanip>
#include <cstring>      // Needed for memset
#include <sys/socket.h> // Needed for the socket functions
#include <sys/types.h>
#include <netdb.h>      // Needed for the socket functions
#include <unistd.h>

#include <opencv/cv.h>
#include <opencv/highgui.h>

#include "rtvproc_types.h"
#include "rtvproc_msg.h"
#include "RTVideoProcessing.h"

using std::cin;
using std::cout;
using std::cerr;
using std::endl;

//////////////////////////////////////////////////////////////////////////////
// variables

bool features_enabled = false;
bool quiet_mode = false;

char* host;
char* port;
int socket_hnd; // The socket descriptor

struct addrinfo host_info;       // The struct that getaddrinfo() fills up with data.
struct addrinfo *host_info_list; // Pointer to the to the linked list of host_info's.

ssize_t bytes_sent;
ssize_t bytes_received;
message_t tx_message;
message_t rx_message;

cv::Mat rx_image;
uchar* frame_data;
unsigned long frame_size;
unsigned int frame_width;
unsigned int frame_height;
unsigned int* rx_hist_arr;
unsigned int* rx_feat_arr;

std::vector<unsigned int> rx_hist;
unsigned int hist_size;

std::vector<unsigned int> rx_feat;
unsigned int feat_size;

unsigned int frame_index = 0;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// setup client
int setup(void)
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
  
  // Now fill up the linked list of host_info structs with google's address information.
  int getaddrinfo_status = getaddrinfo(host, port, &host_info, &host_info_list);
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
    cerr << "socket error " << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  cout << "Connecting..." << endl;
  
  int connect_status = connect(socket_hnd, host_info_list->ai_addr, host_info_list->ai_addrlen);
  if (connect_status == -1)
  {
    cerr << "connect error" << endl;
    status = -1;
  }
  
  //----------------------------------------------------------------------------
  cout << "Sending session request..." << endl;
  
  // send request
  tx_message = RTIMPROC_TX_BEGIN;
  bytes_sent = send(socket_hnd, &tx_message, RTIMPROC_MSGSIZ, 0);
  
  // get ack
  bytes_received = recv(socket_hnd, &rx_message, RTIMPROC_MSGSIZ, 0);
  if (bytes_received == -1)
  {
    cerr << "recv error" << endl;
    status = -1;
  }
  cout << "bytes received = " << bytes_received << endl;
  switch (rx_message)
  {
    case RTIMPROC_ACK:
      cout << "ACK received" << endl;
      break;
    default:
      cerr << "error: " << "0x" << std::hex << rx_message << endl;
      status = -1;
  }
  
  cout << "Session open!" << endl;
  
  //============================================================================
  cout << "Initializing session variables..." << endl;
  
  //----------------------------------------------------------------------------
  // send frame size request
  tx_message = RTIMPROC_FRAME_SZ;
  bytes_sent = send(socket_hnd, &tx_message, RTIMPROC_MSGSIZ, 0);
  
  // wait for response
  unsigned int rx_frame_size_data[2];
  GetData<unsigned int>(socket_hnd, rx_frame_size_data, 2);
  
  frame_width = rx_frame_size_data[0];
  frame_height = rx_frame_size_data[1];
  cout << "frame width = " << frame_width << endl;
  cout << "frame height = " << frame_height << endl;
  
  // allocate memory
  frame_size = frame_width * frame_height * 3;
  cout << "frame size = " << frame_size << endl;
  frame_data = (uchar*)malloc(frame_size*sizeof(uchar));
  
  //----------------------------------------------------------------------------
  // send hist size request
  tx_message = RTIMPROC_HIST_SZ;
  bytes_sent = send(socket_hnd, &tx_message, RTIMPROC_MSGSIZ, 0);
  
  // wait for response
  GetData<unsigned int>(socket_hnd, &hist_size, 1);
  
  // allocate memory
  cout << "hist size = " << hist_size << endl;
  rx_hist_arr = (unsigned int*)malloc((hist_size)*sizeof(unsigned int));
  
  //----------------------------------------------------------------------------
  
  return status;

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// get frame
int get_frame(void)
{
  int status = 1;
  
  cout << "--------------------" << endl;
  
  //============================================================================
  // get frame index
  
  // send frame index request
  SendMessage(socket_hnd, RTIMPROC_FRAME_IDX);
  
  // wait for frame index
  GetData<unsigned int>(socket_hnd, &frame_index, 1);
  
  cout << "frame = " << frame_index << endl;
  
  //============================================================================
  // get frame
  
  // send frame request
  SendMessage(socket_hnd, RTIMPROC_FRAME_RQ);
  
  cout << "Waiting for frame..." << endl;
  
  // get data
  GetData<uchar>(socket_hnd, frame_data, frame_size);
  
  // assign data to image
  rx_image = cv::Mat(frame_height, frame_width, CV_8UC3, frame_data);
  
  cout << "Received frame: " << rx_image.rows << "x" << rx_image.cols << " = " << frame_size << endl;
  
  // display image
  imshow("received image", rx_image);
  cv::waitKey(33);
  
  // send frame rx response
  SendMessage(socket_hnd, RTIMPROC_FRAME_RX);
  
  // get ack
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_ACK);
  
  //============================================================================
  // get hist
  
  // send hist request
  SendMessage(socket_hnd, RTIMPROC_HIST_RQ);
  
  cout << "Waiting for hist..." << endl;
  
  // get data
  GetData<unsigned int>(socket_hnd, rx_hist_arr, hist_size);

  // copy data
  rx_hist.assign(rx_hist_arr,rx_hist_arr+hist_size);
  
  //cout << hist_size << " hist values received" << endl;
  //for (int i = 0; i < 10; i++)
  //  cout << rx_hist.at(i) << ',';
  //cout << ".." << endl;
  
  // send hist rx response
  SendMessage(socket_hnd, RTIMPROC_HIST_RX);
  
  // get ack
  WaitForMessage(socket_hnd, rx_message, RTIMPROC_ACK);
  
  //============================================================================
  // get features
  
  if (features_enabled)
  {
    // send feat size request
    tx_message = RTIMPROC_FEAT_SZ;
    bytes_sent = send(socket_hnd, &tx_message, RTIMPROC_MSGSIZ, 0);
    
    // wait for response
    GetData<unsigned int>(socket_hnd, &feat_size, 1);
    
    cout << "feat size = " << feat_size << endl;
    rx_feat_arr = (unsigned int*)malloc(2*feat_size*sizeof(unsigned int));
    
    // send feat request
    SendMessage(socket_hnd, RTIMPROC_FEAT_RQ);
    
    cout << "Waiting for features..." << endl;
    
    // get data
    GetData<unsigned int>(socket_hnd, rx_feat_arr, 2*feat_size);
    
    // copy data
    rx_feat.assign(rx_feat_arr,rx_feat_arr+2*feat_size);
    free(rx_feat_arr);
    
    // send feat rx response
    SendMessage(socket_hnd, RTIMPROC_FEAT_RX);
    
    // get ack
    WaitForMessage(socket_hnd, rx_message, RTIMPROC_ACK);
  }
  
  //----------------------------------------------------------------------------
  
  return status;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
  // parse args
  std::stringstream usage;
  usage << "usage: ./rtvproc_client";
  usage << " host";
  usage << " port";
  usage << " [--feat]";
  usage << " [--quiet]";
  
  // required args
  if (argc < 3)
  {
    cerr << usage.str() << endl;
    exit(-1);
  }
  host = argv[1];
  port = argv[2];
  
  // optional args
  for (int i = 3; i < argc; i++)
  {
    if (i < argc)
    {
      if (std::string(argv[i]) == "--feat")
      {
        features_enabled = true;
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
    // redirect cout to null_stream
    std::cout.rdbuf(std::ostream(0).flush().rdbuf());
  }
  
  //----------------------------------------------------------------------------
  // setup
  int setup_status = setup();
  if (setup_status < 0)
  {
    cerr << "setup error" << endl;
    exit(-1);
  }
  
  //----------------------------------------------------------------------------
  // get frames
  cout << "----------------------------------------" << endl;
  cout << "Receiving frames:" << endl;
  int frame_status;
  while(1)
  {
    
    frame_status = get_frame();
    
    if (frame_status < 0)
    {
      cerr << "frame error" << endl;
      //exit(-1);
      continue;
    }

  }
  
  //----------------------------------------------------------------------------
  cout << "Closing session..." << endl;
  
  freeaddrinfo(host_info_list);
  close(socket_hnd);
  
  cin.get();
  return 0;
  
}
