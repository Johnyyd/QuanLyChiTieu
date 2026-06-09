# Sơ đồ Use-case Hệ thống Quản lý Chi tiêu

Sơ đồ dưới đây mô tả các ca sử dụng (Use-case) chính của hệ thống từ góc độ người dùng, bao gồm các cụm chức năng từ quản lý tài khoản, quản lý nhóm, quản lý thu chi, cho đến các tính năng nâng cao như quyết toán công nợ tự động và trợ lý AI.

```mermaid
flowchart LR
    %% Định nghĩa Actors
    User([Người dùng])
    Auth[[Google/Firebase Auth]]
    AI[[AI Gemini]]

    %% Các nhóm Use-case
    subgraph TaiKhoan [Quản lý Tài khoản]
        direction TB
        UC1(Đăng ký tài khoản)
        UC2(Đăng nhập)
        UC3(Đăng xuất)
    end

    subgraph Nhom [Quản lý Nhóm]
        direction TB
        UC4(Tạo nhóm mới)
        UC5(Xem danh sách nhóm)
        UC6(Thêm thành viên vào nhóm)
    end

    subgraph ThuChi [Quản lý Thu / Chi]
        direction TB
        UC7(Thêm giao dịch chi tiêu)
        UC8(Ghi nhận thu nhập)
        UC9(Xem lịch sử giao dịch)
        UC14(Thiết lập ngân sách)
    end

    subgraph QuyetToan [Quyết toán Công nợ]
        direction TB
        UC10(Xem số dư - Balance)
        UC11(Thực hiện Quyết toán tự động)
        UC12(Xác nhận thanh toán nợ)
    end
    
    subgraph TietKiem [Quản lý Tiết kiệm]
        direction TB
        UC15(Tạo mục tiêu tiết kiệm)
        UC16(Cập nhật tiến độ quỹ)
    end

    subgraph TroLyAo [Trợ lý ảo]
        UC13(Hỏi đáp & Phân tích tài chính)
    end

    %% Các mối quan hệ
    User --> TaiKhoan
    User --> Nhom
    User --> ThuChi
    User --> QuyetToan
    User --> TietKiem
    User --> TroLyAo

    UC1 -.->|include| Auth
    UC2 -.->|include| Auth
    UC13 -.->|include| AI
```

### Đặc tả các Use-case chính

1. **Quản lý Nhóm:** Người dùng có thể khởi tạo các nhóm chung (nhóm du lịch, nhóm phòng trọ) và mời bạn bè tham gia. Mọi thành viên trong nhóm có quyền bình đẳng trong việc thêm mới chi tiêu.
2. **Quản lý Thu/Chi:** Tính năng cốt lõi cho phép người dùng ghi nhận số tiền, diễn giải, chọn người thanh toán và phân bổ chi phí cho những ai trong nhóm.
3. **Quyết toán Công nợ:** Ứng dụng tự động tính toán tổng số tiền mỗi người đã trả và thực tiêu, sau đó sử dụng thuật toán cấn trừ để tối ưu hóa số vòng chuyển khoản, giúp các thành viên trả nợ lẫn nhau một cách nhanh gọn nhất.
4. **Quản lý Tiết kiệm:** Hỗ trợ thiết lập các mục tiêu tài chính cá nhân (như mua xe, mua nhà) và liên tục theo dõi tiến độ hoàn thành dựa trên số tiền tích lũy.
5. **Trợ lý ảo (AI Gemini):** Người dùng có thể giao tiếp với AI chatbot. AI sẽ truy xuất dữ liệu chi tiêu, thu nhập và tiết kiệm thực tế của người dùng để đưa ra nhận xét, đánh giá và lời khuyên tài chính cá nhân hóa.