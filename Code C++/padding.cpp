#include <iostream>
#include <vector>

using namespace std;

void addPadding(const vector<float>& image, vector<float>& matrixP, int N, int p) {
    // Tính kích thước mới sau khi thêm padding
    int newSize = N + 2 * p;
    matrixP = vector<float>(newSize * newSize, 0.0f); // Khởi tạo ma trận padding với toàn bộ giá trị = 0

    int t1 = 0; // Con trỏ tương tự `$t1`, chỉ vị trí lưu `matrixP`

    // **1. Thêm padding phía trên (p hàng đầu tiên toàn 0)**
    for (int i = 0; i < p; ++i) {
        for (int j = 0; j < newSize; ++j) {
            matrixP[t1] = 0.0f; // Ghi giá trị 0 vào vùng trên
            ++t1;               // Tăng con trỏ t1
        }
    }

    // **2. Thêm phần giữa (padding trái/phải và sao chép dữ liệu từ image)**
    int t7 = 0; // Con trỏ tương tự `$s7`, chỉ vị trí trong mảng image
    for (int i = 0; i < N; ++i) {
        // **Thêm padding trái (p cột đầu tiên toàn 0)**
        for (int j = 0; j < p; ++j) {
            matrixP[t1] = 0.0f;
            ++t1;
        }

        // **Sao chép dữ liệu từ `image`**
        for (int j = 0; j < N; ++j) {
            matrixP[t1] = image[t7]; // Lấy giá trị từ `image` và gán vào `matrixP`
            ++t1;                    // Tăng con trỏ `matrixP`
            ++t7;                    // Tăng con trỏ `image`
        }

        // **Thêm padding phải (p cột cuối cùng toàn 0)**
        for (int j = 0; j < p; ++j) {
            matrixP[t1] = 0.0f;
            ++t1;
        }
    }

    // **3. Thêm padding phía dưới (p hàng cuối toàn 0)**
    for (int i = 0; i < p; ++i) {
        for (int j = 0; j < newSize; ++j) {
            matrixP[t1] = 0.0f; // Ghi giá trị 0 vào vùng dưới
            ++t1;
        }
    }
}

void printMatrix(const vector<float>& matrix, int size) {
    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            cout << matrix[i * size + j] << " "; // Truy cập mảng 1 chiều theo hàng và cột
        }
        cout << endl;
    }
}

int main() {
    int N = 3; // Kích thước ma trận gốc (3x3)
    int p = 1; // Padding (số lượng hàng/cột thêm vào mỗi cạnh)

    // Ma trận gốc lưu dưới dạng mảng 1 chiều
    vector<float> image = {
        1, 2, 3,
        4, 5, 6,
        7, 8, 9
    };

    // Ma trận sau padding (kết quả)
    vector<float> matrixP;

    // Gọi hàm thêm padding
    addPadding(image, matrixP, N, p);

    // Kích thước ma trận sau padding
    int newSize = N + 2 * p;

    // In kết quả
    cout << "Matrix after adding padding:" << endl;
    printMatrix(matrixP, newSize);

    return 0;
}
