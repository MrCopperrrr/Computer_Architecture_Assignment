#include <iostream>
#include <vector>
#include <fstream>
#include <iomanip>

using namespace std;

// Hàm để đọc ma trận từ tệp
vector<vector<double>> readMatrix(ifstream &file, int size) {
    vector<vector<double>> matrix(size, vector<double>(size));
    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            file >> matrix[i][j];
        }
    }
    return matrix;
}

// Hàm áp dụng padding lên ma trận
vector<vector<double>> applyPadding(const vector<vector<double>>& matrix, int padding) {
    int originalSize = matrix.size();
    int newSize = originalSize + 2 * padding;
    vector<vector<double>> paddedMatrix(newSize, vector<double>(newSize, 0.0));

    for (int i = 0; i < originalSize; ++i) {
        for (int j = 0; j < originalSize; ++j) {
            paddedMatrix[i + padding][j + padding] = matrix[i][j];
        }
    }
    return paddedMatrix;
}

// Hàm thực hiện phép tích chập với padding và stride
vector<vector<double>> convolve2D(const vector<vector<double>>& input, const vector<vector<double>>& kernel, int stride) {
    int inputSize = input.size();
    int kernelSize = kernel.size();
    int outputSize = (inputSize - kernelSize) / stride + 1;
    
    vector<vector<double>> output(outputSize, vector<double>(outputSize, 0.0));
    
    for (int i = 0; i < outputSize; ++i) {
        for (int j = 0; j < outputSize; ++j) {
            double sum = 0.0;
            for (int ki = 0; ki < kernelSize; ++ki) {
                for (int kj = 0; kj < kernelSize; ++kj) {
                    sum += input[i * stride + ki][j * stride + kj] * kernel[ki][kj];
                }
            }
            output[i][j] = sum;
        }
    }
    return output;
}

int main() {
    ifstream file("C:\\Users\\DELL\\Downloads\\btl ktmt\\input_matrix.txt");
    if (!file) {
        cerr << "Không thể mở file input_matrix.txt" << endl;
        return 1;
    }

    int N, M, p, s;
    file >> N >> M >> p >> s;
    
    vector<vector<double>> image = readMatrix(file, N);
    vector<vector<double>> kernel = readMatrix(file, M);

    // Áp dụng padding cho ma trận ảnh
    vector<vector<double>> paddedImage = applyPadding(image, p);

    // Tính tích chập với padding và stride
    vector<vector<double>> output = convolve2D(paddedImage, kernel, s);

    // Ghi kết quả vào tệp output_matrix.txt
    ofstream outputFile("C:\\Users\\DELL\\Downloads\\btl ktmt\\output_matrix.txt");
    if (!outputFile) {
        cerr << "khong the mo file output_matrix.txt" << endl;
        return 1;
    }

    for (const auto& row : output) {
        for (double val : row) {
            outputFile << fixed << setprecision(1) << val << " ";
        }
        outputFile << endl;
    }

    cout << "ket qua duoc ghi file output_matrix.txt" << endl;

    return 0;
}
