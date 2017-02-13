//
//  rtimproc_types.h
//  rtimproc-server
//
//  Created by Mikhail Volkov on 4/18/14.
//  Copyright (c) 2014 Mikhail Volkov. All rights reserved.
//

#ifndef rtimproc_server_rtimproc_types_h
#define rtimproc_server_rtimproc_types_h

typedef enum
{
  RTIMPROC_SRC_CAPTURE,
  RTIMPROC_SRC_VIDEO
} rtimproc_src_mode;

typedef unsigned int message_t;
const size_t RTIMPROC_MSGSIZ = sizeof(message_t);

const message_t RTIMPROC_TX_BEGIN  = 0xAA01;
const message_t RTIMPROC_TX_END    = 0xAA02;
const message_t RTIMPROC_TX_RESET  = 0xAA04;
const message_t RTIMPROC_FRAME_SZ  = 0xAA11;
const message_t RTIMPROC_HIST_SZ   = 0xAA12;
const message_t RTIMPROC_FRAME_IDX = 0xAA21;
const message_t RTIMPROC_FRAME_RQ  = 0xAA41;
const message_t RTIMPROC_FRAME_RX  = 0xAA42;
const message_t RTIMPROC_HIST_RQ   = 0xAA81;
const message_t RTIMPROC_HIST_RX   = 0xAA82;
const message_t RTIMPROC_FEAT_SZ   = 0xAA31;
const message_t RTIMPROC_FEAT_RQ   = 0xAA32;
const message_t RTIMPROC_FEAT_RX   = 0xAA34;
const message_t RTIMPROC_ACK       = 0xAAFF;

#endif