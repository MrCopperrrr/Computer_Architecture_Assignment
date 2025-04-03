#include <iostream>
#include <vector>

using namespace std;

// Hàm tính tích chập cho một ma trận ảnh (image) và kernel
void convolution(const vector<float>& image, const vector<float>& kernel, 
                 int image_height, int image_width, 
                 int kernel_height, int kernel_width, 
                 int stride, int padding, 
                 vector<float>& output) {
    // Kích thước của ma trận đầu ra
    int output_height = (image_height + 2 * padding - kernel_height) / stride + 1;
    int output_width = (image_width + 2 * padding - kernel_width) / stride + 1;

    // Duyệt qua các phần tử của ma trận đầu ra
    for (int i = 0; i < output_height; ++i) {
        for (int j = 0; j < output_width; ++j) {
            float sum = 0.0f;
            // Duyệt qua kernel
            for (int ki = 0; ki < kernel_height; ++ki) {
                for (int kj = 0; kj < kernel_width; ++kj) {
                    // Tính chỉ số của phần tử trong ma trận ảnh
                    int img_x = i * stride + ki - padding;
                    int img_y = j * stride + kj - padding;

                    // Kiểm tra xem pixel có nằm trong ảnh không (padding là vùng ngoài ảnh)
                    if (img_x >= 0 && img_x < image_height && img_y >= 0 && img_y < image_width) {
                        // Tính chỉ số của phần tử trong mảng 1 chiều của ảnh
                        int img_index = img_x * image_width + img_y;
                        // Tính chỉ số của phần tử trong mảng 1 chiều của kernel
                        int kernel_index = ki * kernel_width + kj;
                        // Cộng dồn giá trị vào tổng tích chập
                        sum += image[img_index] * kernel[kernel_index];
                    }
                }
            }
            // Lưu giá trị tính được vào ma trận đầu ra (mảng 1 chiều)
            int output_index = i * output_width + j;
            output[output_index] = sum;
        }
    }
}

int main() {
    // Kích thước ảnh và kernel
    int image_height = 3, image_width = 3;
    int kernel_height = 2, kernel_width = 2;
    int stride = 1, padding = 0;

    // Khởi tạo mảng ảnh và kernel (1D)
    vector<float> image = {
        1, 2, 3, 4, 5,
        6, 7, 8, 9
    };

    vector<float> kernel = {
        1, 1, 1,1 
    };

    // Tính toán kích thước ma trận đầu ra
    int output_height = (image_height + 2 * padding - kernel_height) / stride + 1;
    int output_width = (image_width + 2 * padding - kernel_width) / stride + 1;

    // Mảng chứa kết quả của phép tích chập (output)
    vector<float> output(output_height * output_width, 0.0f);

    // Thực hiện phép tích chập
    convolution(image, kernel, image_height, image_width, 
                kernel_height, kernel_width, stride, padding, output);

    // In kết quả đầu ra
    cout << "Output Matrix (after convolution):" << endl;
    for (int i = 0; i < output_height; ++i) {
        for (int j = 0; j < output_width; ++j) {
            int output_index = i * output_width + j;
            cout << output[output_index] << " ";
        }
        cout << endl;
    }

    return 0;
}
