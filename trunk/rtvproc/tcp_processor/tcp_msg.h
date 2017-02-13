//
//  rtimproc_msg.h.h
//  rtimproc-server
//
//  Created by Mikhail Volkov on 4/24/14.
//  Copyright (c) 2014 Mikhail Volkov. All rights reserved.
//

#ifndef rtimproc_server_rtimproc_msg_h
#define rtimproc_server_rtimproc_msg_h

#include <iostream>
#include <unistd.h>
#include "rtvproc_types.h"

using std::cout;
using std::cerr;
using std::endl;

// send protocol message
int SendMessage(const int& socket_hnd, const message_t& tx_message)
{
  int status = 1;
  
  ssize_t bytes_sent = send(socket_hnd, &tx_message, RTIMPROC_MSGSIZ, 0);
  
  //cout << "bytes sent = " << bytes_sent << endl;
  
  if (bytes_sent == 0)
  {
    cerr << "send error" << endl;
    status = -1;
  }
  
  return status;
}

// wait for protocol message
static int WaitForMessage(const int& socket_hnd, message_t& rx_message, const message_t& expected_message)
{
  int status = 1;
  
  ssize_t bytes_received = recv(socket_hnd, &rx_message, RTIMPROC_MSGSIZ, 0);
  
  if (bytes_received == -1)
  {
    cerr << "recv error" << endl;
    status = -1;
  }
  else
  {
    //cout << "bytes received = " << bytes_received << endl;
  }
  
  // verify message
  if (rx_message == expected_message)
  {
    cout << "verified: " << "0x" << std::hex << rx_message << std::dec << endl;
  }
  else
  {
    cerr << "error: " << "0x" << std::hex << rx_message << std::dec << endl;
    cerr << "expected: " << "0x" << std::hex << expected_message << std::dec << endl;
    status = -1;
  }
  
  return status;
}

template<typename T>
static int GetData(const int& socket_hnd, T* data, const unsigned long size)
{
  int status = 1;
  
  int offset = 0;
  while (offset < size)
  {
    ssize_t bytes_received = recv(socket_hnd, data+offset, (size-offset)*sizeof(T), 0);
    //cout << "bytes received = " << bytes_received << endl;
    if (bytes_received == -1)
    {
      cerr << "recv error" << endl;
      status = -1;
    }
    offset += bytes_received;
  }
  cout << "total bytes received = " << offset << endl;
  
  return status;
}

#endif
