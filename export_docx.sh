#!/bin/bash

echo "=========================================================="
echo "BẮT ĐẦU QUÁ TRÌNH XUẤT FILE DOCX TỪ MARKDOWN"
echo "=========================================================="

# Kiểm tra npm/npx
if ! command -v npx &> /dev/null; then
    echo "Lỗi: Không tìm thấy 'npx'. Vui lòng cài đặt Node.js và npm trước."
    exit 1
fi

# Kiểm tra pandoc
if ! command -v pandoc &> /dev/null; then
    echo "Lỗi: Không tìm thấy 'pandoc'. Vui lòng cài đặt pandoc trước (VD: sudo apt install pandoc)."
    exit 1
fi

# Kiểm tra file tham chiếu
if [ ! -f "KLCN13_TranThiVanAnh.docx" ]; then
    echo "Lỗi: Không tìm thấy file tham chiếu 'KLCN13_TranThiVanAnh.docx' trong thư mục hiện tại!"
    exit 1
fi

echo "1. Đang xử lý các biểu đồ Mermaid thành ảnh PNG..."
# mmdc sẽ tự động đọc file .md, render các khối mermaid thành file .png và xuất ra file md mới chứa link ảnh
npx -y @mermaid-js/mermaid-cli -i thesis_content.md -o thesis_content_with_images.md -e png -s 4 -b white -p puppeteer-config.json

if [ $? -ne 0 ]; then
    echo "Lỗi khi render ảnh bằng mermaid-cli."
    exit 1
fi

echo "2. Đang chuyển đổi sang file Word bằng Pandoc..."
pandoc thesis_content_with_images.md -o Nhom12_DeTai6_NguyenMinhTri.docx --reference-doc=KLCN13_TranThiVanAnh.docx

if [ $? -eq 0 ]; then
    echo "=========================================================="
    echo "THÀNH CÔNG!"
    echo "Đã tạo thành công file: Nhom12_DeTai6_NguyenMinhTri.docx"
    echo "Các biểu đồ đã được nhúng dưới dạng ảnh chuẩn để hiển thị trong Word."
    echo "=========================================================="
else
    echo "Lỗi: Quá trình xuất file Word bằng Pandoc thất bại."
    exit 1
fi
