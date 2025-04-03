import numpy as np

def convolve(image, kernel, padding=0, stride=1):
    # Kích thước ma trận đầu vào (N x N)
    n, _ = image.shape
    # Kích thước kernel (M x M)
    m, _ = kernel.shape
    
    # Thêm padding vào ma trận đầu vào
    if padding > 0:
        image = np.pad(image, pad_width=padding, mode='constant', constant_values=0)
    
    # Kích thước của ma trận đã thêm padding
    padded_n = image.shape[0]
    
    # Tính toán kích thước ma trận kết quả
    output_size = ((padded_n - m) // stride) + 1
    output = np.zeros((output_size, output_size))
    
    # Thực hiện phép tính tích chập
    for i in range(0, output_size):
        for j in range(0, output_size):
            # Lấy vùng (sub-matrix) từ ma trận đầu vào
            sub_matrix = image[i*stride:i*stride + m, j*stride:j*stride + m]
            # Tính tổng tích nhân và lưu kết quả
            output[i, j] = np.sum(sub_matrix * kernel)
    
    return output

# Đọc dữ liệu từ tệp input_matrix.txt
with open('input_matrix.txt', 'r') as file:
    # Đọc dòng đầu tiên (các giá trị N, M, p, s)
    N, M, p, s = map(int, file.readline().split())
    
    # Đọc ma trận ảnh và kernel từ hai dòng tiếp theo
    image_values = list(map(float, file.readline().split()))
    kernel_values = list(map(float, file.readline().split()))
    
    # Chuyển đổi danh sách thành ma trận N x N
    image = np.array(image_values).reshape(N, N)
    
    # Chuyển đổi danh sách thành ma trận M x M
    kernel = np.array(kernel_values).reshape(M, M)

# In đầu vào để kiểm tra
print("Image Matrix:\n", image)
print("Kernel Matrix:\n", kernel)

# Thực hiện tính toán
output = convolve(image, kernel, padding=p, stride=s)
print("Convolution Result:\n", output)
