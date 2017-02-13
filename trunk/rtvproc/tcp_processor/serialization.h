#include <iostream>
#include <fstream>
#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/serialization/split_free.hpp>
#include <boost/serialization/vector.hpp>

#include "opencv/cv.h"

// Serialization support for cv::Mat
BOOST_SERIALIZATION_SPLIT_FREE(cv::Mat)

namespace boost {
  
  namespace serialization {
    
    template<class Archive>
    void save(Archive & ar, const ::cv::Mat& m, const unsigned int version)
    {
      size_t elem_size = m.elemSize();
      size_t elem_type = m.type();
      
      ar & m.cols;
      ar & m.rows;
      ar & elem_size;
      ar & elem_type;
      
      const size_t data_size = m.cols * m.rows * elem_size;
      ar & boost::serialization::make_array(m.ptr(), data_size);
    }
    
    template<class Archive>
    void load(Archive & ar, ::cv::Mat& m, const unsigned int version)
    {
      int cols, rows;
      size_t elem_size, elem_type;
      
      ar & cols;
      ar & rows;
      ar & elem_size;
      ar & elem_type;
      
      m.create(rows, cols, elem_type);
      
      size_t data_size = m.cols * m.rows * elem_size;
      ar & boost::serialization::make_array(m.ptr(), data_size);
    }
    
  }
  
}

template<class T>
std::string Serialize(T obj)
{
  std::string s;
  try
  {
    std::ostringstream oss;
    boost::archive::text_oarchive oa(oss);
    oa << obj;
    std::string s = oss.str();
  }
  catch (const std::exception & e)
  {
    std::cerr << e.what() << std::endl;
  }
  return s;
}

template<class T>
T Deserialize(std::string s)
{
  T obj;
  try
  {
    std::istringstream iss;
    iss >> s;
    boost::archive::text_iarchive ia(iss);
    ia >> obj;
  }
  catch (const std::exception & e)
  {
    std::cerr << e.what() << std::endl;
  }
  return obj;
}


