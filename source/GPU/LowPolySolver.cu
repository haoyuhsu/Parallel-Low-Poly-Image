 #include <cstdio>
#include <cstdlib>
#include <iostream>
#include <string>

#include <vector>

#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc/imgproc.hpp>

#include "point.h"
#include "triangle.h"
#include "delauney.h"
#include "img_utils.h"

using namespace std;


int main(int argc, char **argv)
{
    string image_path = argv[1];
    string output_folder = argv[2];
    cv::Mat img = cv::imread(image_path, cv::IMREAD_COLOR);
 
    if(img.empty())
    {
        std::cout << "Could not read the image: " << image_path << std::endl;
        return 1;
    }

    int height = img.rows;
    int width = img.cols;

    cout << "height: " << height << ", width: " << width << endl;

    cv::Mat img_grey;
    cv::cvtColor(img, img_grey, cv::COLOR_BGR2GRAY);

    int totalPixel = height * width;
    uint8_t *gradient_img = (uint8_t *)malloc(sizeof(uint8_t) * totalPixel);
    uint8_t *grey_img = img_grey.data;

    select_vertices_GPU(grey_img, gradient_img, height, width);

    // ****************************
    // for output edge image
    cv::Mat edge_output = drawEdges(gradient_img, height, width);
    cv::imwrite( output_folder + "/GPU_edge.jpg", edge_output );
    // ****************************

    Point *owner_map_CPU = (Point *)malloc(sizeof(Point) * totalPixel);
    vector<Triangle> triangles;
    delauney_GPU(owner_map_CPU, triangles, height, width);

    // ****************************
    // for output voroni images
    cv::Mat voroni_output = drawVoroni(owner_map_CPU, height, width);
    cv::imwrite( output_folder + "/GPU_voroni.jpg", voroni_output );
    // for output voroni + triangle images
    cv::Mat voroni_tri_output = drawTriangles(triangles, voroni_output, true);
    cv::imwrite( output_folder + "/GPU_voroni_triangle.jpg", voroni_tri_output );
    // for output triangle on original images
    cv::Mat orig_tri_output = drawTriangles(triangles, img, true);
    cv::imwrite( output_folder + "/GPU_original_triangle.jpg", orig_tri_output );
    // ****************************

    // ****************************
    // for output final image
    cv::Mat final_output = drawLowPoly_GPU(img);
    cv::imwrite( output_folder + "/GPU_final.jpg", final_output );
    // ****************************

    free(gradient_img);
    free(owner_map_CPU);

    return 0;
}