# BỘ CÔNG THƯƠNG
# TRƯỜNG ĐẠI HỌC CÔNG THƯƠNG TP. HCM
# KHOA CÔNG NGHỆ THÔNG TIN
---

**ĐỒ ÁN HỌC PHẦN LẬP TRÌNH DI ĐỘNG**

# XÂY DỰNG ỨNG DỤNG QUẢN LÝ CHI TIÊU THEO NHÓM (NHIỀU NHÓM, NHIỀU LOẠI CHI TIÊU)

**Ngành: Công Nghệ Thông Tin**

**GIẢNG VIÊN HƯỚNG DẪN:**
Nguyễn Thanh Truyền

**SINH VIÊN THỰC HIỆN:**
1. 2001225553 – Nguyễn Minh Trí – 13DHTH08

*TP. HỒ CHÍ MINH, tháng...,năm 202...*

---

## MỤC LỤC
1. [MỞ ĐẦU](#mở-đầu)
2. [CHƯƠNG 1: KHẢO SÁT HỆ THỐNG](#chương-1-khảo-sát-hệ-thống)
3. [CHƯƠNG 2: PHÂN TÍCH HỆ THỐNG](#chương-2-phân-tích-hệ-thống)
4. [CHƯƠNG 3: THIẾT KẾ HỆ THỐNG](#chương-3-thiết-kế-hệ-thống)
5. [CHƯƠNG 4: CÀI ĐẶT HỆ THỐNG](#chương-4-cài-đặt-hệ-thống)
6. [CHƯƠNG 5: THỬ NGHIỆM VÀ TRIỂN KHAI](#chương-5-thử-nghiệm-và-triển-khai)
7. [KẾT LUẬN](#kết-luận)

---

## MỞ ĐẦU

### 1. GIỚI THIỆU
Trong bối cảnh đời sống xã hội ngày càng phát triển, nhu cầu giao lưu, tổ chức các hoạt động chung như du lịch, ăn uống, sự kiện của các nhóm bạn trẻ, đồng nghiệp hay gia đình ngày càng tăng cao. Kéo theo đó là nhu cầu quản lý tài chính, đặc biệt là việc ghi chép và chia sẻ chi phí chung (chia tiền) giữa các thành viên trong nhóm. 

Tuy nhiên, thực tế hiện nay cho thấy việc quản lý chi tiêu nhóm thường được thực hiện thủ công qua sổ sách, tin nhắn hoặc ứng dụng ghi chú đơn giản. Phương pháp này bộc lộ nhiều điểm hạn chế như: dễ nhầm lẫn, mất dữ liệu, khó theo dõi, đặc biệt là tính toán chia tiền (người trả hộ, người tham gia, người không tham gia) mất rất nhiều thời gian và dễ gây hiểu lầm. Nhận thấy những rào cản đó, việc phát triển một hệ thống ứng dụng di động quản lý chi tiêu nhóm thông minh, tự động tính toán quyết toán (settlement) là một nhu cầu vô cùng cấp thiết. Đó cũng chính là lý do đề tài này được lựa chọn để nghiên cứu và phát triển.

### 2. MỤC TIÊU ĐỀ TÀI
Đề tài được thực hiện nhằm hướng tới các mục tiêu cốt lõi sau:
- **Xây dựng hệ thống ứng dụng di động tiện lợi:** Phát triển một ứng dụng Mobile mượt mà, trực quan, hỗ trợ người dùng có thể thao tác mọi lúc mọi nơi để ghi nhận các khoản thu/chi.
- **Quản lý đa nhóm, đa loại chi tiêu:** Cho phép người dùng tham gia và quản lý nhiều nhóm khác nhau (vd: nhóm du lịch, nhóm phòng trọ, nhóm công ty), phân loại chi tiêu rõ ràng.
- **Tự động hóa tính toán quyết toán (Settlement):** Tích hợp thuật toán đối trừ công nợ để tính toán ra phương án trả nợ tối ưu nhất (ai cần trả cho ai bao nhiêu tiền) nhằm thanh toán dứt điểm công nợ trong nhóm.
- **Đồng bộ hóa dữ liệu thời gian thực (Real-time):** Dữ liệu chi tiêu được đồng bộ ngay lập tức tới tất cả các thành viên trong nhóm để đảm bảo tính minh bạch nhờ công nghệ Cloud.

### 3. ĐỐI TƯỢNG VÀ PHẠM VI ĐỀ TÀI
- **Đối tượng nghiên cứu:** Các quy trình thu chi, tính toán chia tiền, phân bổ công nợ trong các hoạt động đội nhóm thực tế. Các đối tượng vật lý gồm: người dùng (user), nhóm (group), khoản chi tiêu (expense), và lịch sử quyết toán (settlement).
- **Phạm vi nghiệp vụ:** Hệ thống được giới hạn trong việc giải quyết bài toán đăng ký, đăng nhập, quản lý danh sách nhóm, thêm/sửa/xóa khoản chi, xem thống kê chi phí và tự động gợi ý cách thanh toán.
- **Phạm vi công nghệ:** Đề tài ứng dụng kiến trúc phần mềm linh hoạt, sử dụng Framework Flutter (ngôn ngữ Dart) để phát triển ứng dụng di động đa nền tảng (Android/iOS) kết hợp cùng hệ sinh thái Firebase (Firebase Auth, Cloud Firestore) để lưu trữ và xử lý dữ liệu theo thời gian thực.

---

## CHƯƠNG 1: KHẢO SÁT HỆ THỐNG

### 1.1. MỤC TIÊU KHẢO SÁT
Mục đích chính của bước khảo sát là tìm hiểu cặn kẽ cách thức các nhóm (sinh viên, nhân viên văn phòng) đang thực hiện việc chia sẻ chi phí hiện nay. Từ những dữ liệu thu thập được, đề tài sẽ tiến hành ánh xạ các yêu cầu thực tế thành các chức năng của phần mềm, đảm bảo ứng dụng giải quyết đúng "nỗi đau" (pain points) của người dùng.

### 1.2. HIỆN TRẠNG TỔ CHỨC VÀ QUY TRÌNH NGHIỆP VỤ

**1.2.1. Cấu trúc vai trò**
Khác với các hệ thống doanh nghiệp đòi hỏi phân quyền phức tạp, ứng dụng Quản lý chi tiêu nhóm hướng tới sự tối giản, linh hoạt và thuận tiện tối đa cho người sử dụng (đặc biệt là trong các chuyến du lịch, đi chơi chung). Do đó, hệ thống không áp dụng cơ chế phân quyền khắt khe mà tập trung vào một vai trò trung tâm duy nhất:
- **Người dùng (User/Member):** Bất kỳ người dùng nào sau khi đăng nhập đều có quyền hạn bình đẳng. Mọi người dùng đều có thể tự do tạo nhóm mới, thêm thành viên vào nhóm, cũng như ghi nhận các khoản chi tiêu chung. Sự bình đẳng này giúp nhóm không bị phụ thuộc vào một cá nhân "thủ quỹ" duy nhất, ai cũng có thể chủ động cập nhật dữ liệu tài chính của nhóm mọi lúc mọi nơi.

**1.2.2. Đặc tả Quy trình quản lý chi tiêu nhóm**
Quy trình hoạt động của hệ thống được thiết kế tinh gọn, bám sát vào nhu cầu thực tế của các nhóm bạn bè/gia đình, bao gồm các bước nghiệp vụ sau:
- **1. Tạo nhóm và mời thành viên:** Một người dùng khởi tạo nhóm (ví dụ: "Du lịch Đà Lạt") và chia sẻ nhóm hoặc thêm trực tiếp các thành viên khác vào. Đây là không gian làm việc chung để mọi người cùng theo dõi một luồng chi phí.
- **2. Ghi nhận giao dịch chi tiêu:** Khi phát sinh chi phí (ví dụ: ăn uống, đi lại), bất kỳ thành viên nào cũng có thể tạo giao dịch mới. Hệ thống yêu cầu nhập rõ: Số tiền, Nội dung, Người đã trả tiền (Paid By) và Những người cùng chia sẻ khoản chi này.
- **3. Theo dõi số dư (Balance):** Xuyên suốt quá trình hoạt động, ứng dụng tự động tổng hợp và tính toán số tiền mỗi cá nhân đã trả hộ so với số tiền thực tế họ phải chịu. Từ đó, cập nhật liên tục trạng thái "đang nợ" hay "được nhận lại" của từng người.
- **4. Quyết toán (Settlement):** Khi kết thúc chuyến đi, người dùng sử dụng tính năng quyết toán. Thay vì phải tự đối soát thủ công phức tạp, hệ thống tự động tổng hợp công nợ và đưa ra phương án chuyển khoản cấn trừ tối ưu nhất (ai chuyển cho ai, bao nhiêu tiền) để giải quyết dứt điểm các khoản nợ trong nhóm.

### 1.3. KẾT CHƯƠNG
Chương 1 đã hoàn thành mục tiêu khảo sát và làm rõ hiện trạng tổ chức cũng như quy trình nghiệp vụ thực tế trong việc quản lý chi tiêu của các đội nhóm. Qua đó, đề tài đã xác định được cấu trúc phân quyền tối giản, hướng tới sự thuận tiện bằng cách trao quyền bình đẳng cho mọi Người dùng (User). Đồng thời, quá trình khảo sát cũng đã đặc tả chi tiết các bước trong quy trình quản lý, từ việc thiết lập nhóm cho đến các công đoạn ghi nhận giao dịch, theo dõi số dư và tự động hóa quyết toán.

Những dữ liệu thực tiễn và các quy trình nghiệp vụ thu thập được trong chương này đóng vai trò là nền tảng cốt lõi. Dựa trên những thông tin này, đề tài đã có đủ cơ sở vững chắc để tiến hành ánh xạ (mapping) các yêu cầu nghiệp vụ vào mô hình dữ liệu (Data Model) của hệ thống Quản lý chi tiêu. Đây sẽ là tiền đề mang tính quyết định để bước sang Chương 2, nơi tập trung vào việc phân tích và thiết kế hệ thống, nhằm hiện thực hóa một giải pháp phần mềm quản lý toàn diện, vận hành tối ưu và đáp ứng tuyệt đối các nhu cầu thực tế của người dùng.

---

## CHƯƠNG 2: PHÂN TÍCH HỆ THỐNG

### 2.1. GIỚI THIỆU
Giai đoạn phân tích hệ thống là bước trọng yếu để định hình rõ các yêu cầu về mặt nghiệp vụ cũng như xác định các luồng thao tác của người dùng trên ứng dụng.

### 2.2. MÔ HÌNH HÓA NGHIỆP VỤ

**2.2.1. Sơ đồ Use-case hệ thống**
Hệ thống gồm các Actor chính là: Người dùng (User).
Các Use-case chính bao gồm:
- Đăng ký / Đăng nhập
- Quản lý Nhóm (Tạo nhóm, Xem danh sách, Thêm/Xóa thành viên)
- Quản lý Chi tiêu (Thêm giao dịch, Sửa/Xóa giao dịch)
- Theo dõi thống kê và Quyết toán (Tính toán công nợ, Xác nhận thanh toán)

**2.2.2. Đặc tả Use Case cốt lõi**

**1. Use case: Quản lý chi tiêu (Thêm giao dịch)**
- **Tóm tắt:** Người dùng thêm một khoản chi mới vào nhóm, ghi nhận số tiền và phân bổ chi phí.
- **Dòng sự kiện chính:**
  1. Người dùng vào chi tiết một Nhóm, nhấn nút "Thêm chi tiêu".
  2. Nhập số tiền, tên khoản chi, chọn loại/danh mục chi tiêu.
  3. Chọn "Người thanh toán" (mặc định là người đang thao tác).
  4. Chọn "Những người tham gia chia sẻ khoản chi" (chia đều hoặc chia theo tỷ lệ/số tiền cụ thể).
  5. Nhấn Lưu, hệ thống đồng bộ dữ liệu lên Firebase Firestore.
  6. Các thành viên khác trong nhóm nhận được thông tin cập nhật tức thì.

**2. Use case: Quyết toán (Settlement)**
- **Tóm tắt:** Hệ thống tính toán đối trừ công nợ để đưa ra số tiền cần thanh toán giữa các thành viên.
- **Dòng sự kiện chính:**
  1. Người dùng chọn tab "Quyết toán" trong Nhóm.
  2. Hệ thống tải toàn bộ lịch sử chi tiêu, tính toán tổng số tiền mỗi người đã trả và tổng số tiền mỗi người thực sự tiêu (phải trả).
  3. Tính toán độ chênh lệch (Balance) của từng người.
  4. Áp dụng thuật toán tối ưu hóa công nợ để sinh ra các giao dịch thanh toán đơn giản nhất (ví dụ: thay vì A trả B, B trả C, hệ thống sẽ gợi ý A trả thẳng cho C).
  5. Hiển thị danh sách cần chuyển khoản. Khi có người chuyển, nhấn "Xác nhận đã thanh toán".

### 2.4. SƠ ĐỒ LỚP MỨC PHÂN TÍCH
Các thực thể chính:
- `User`: id, name, email, avatarUrl.
- `Group`: id, name, description, createdBy, members (List of User IDs).
- `Expense`: id, groupId, title, amount, category, date, paidBy (User ID), splitAmong (Map of User IDs and their shares).
- `Settlement`: id, groupId, fromUser, toUser, amount, isSettled, date.

---

## CHƯƠNG 3: THIẾT KẾ HỆ THỐNG

### 3.1. MÔ HÌNH DỮ LIỆU
Do sử dụng cơ sở dữ liệu NoSQL (Firebase Firestore), dữ liệu được tổ chức dưới dạng các Collections và Documents:
- **Collection `users`:** Lưu thông tin tài khoản đăng nhập.
- **Collection `groups`:** Lưu thông tin nhóm. Mỗi nhóm có thể chứa danh sách `members` dạng array để truy vấn nhanh.
- **Collection `expenses`:** Chứa thông tin các giao dịch. Để truy vấn theo nhóm, document sẽ có field `groupId` được đánh index.
- **Collection `settlements`:** Lưu các khoản đã thanh toán cấn trừ để làm lịch sử.

### 3.2. THIẾT KẾ GIAO DIỆN
- **Màn hình Đăng nhập / Đăng ký:** Giao diện tối giản, hỗ trợ đăng nhập bằng Email/Password hoặc Google.
- **Màn hình Trang chủ (Danh sách Nhóm):** Hiển thị các nhóm người dùng đang tham gia, tổng quan số dư (bạn đang nợ bao nhiêu, người khác nợ bạn bao nhiêu).
- **Màn hình Chi tiết Nhóm:** Gồm các Tab:
  - *Chi tiêu:* Liệt kê các khoản chi dạng danh sách.
  - *Thành viên:* Danh sách người trong nhóm.
  - *Quyết toán:* Đồ thị hoặc danh sách hiển thị các khoản nợ cần thanh toán.
- **Màn hình Thêm chi tiêu:** Form nhập liệu hiện đại, hỗ trợ chọn nhiều người cùng lúc, bàn phím số to rõ.

---

## CHƯƠNG 4: CÀI ĐẶT HỆ THỐNG

### 4.1. CÔNG CỤ VÀ MÔI TRƯỜNG PHÁT TRIỂN
Dự án được xây dựng dựa trên các công nghệ hiện đại:
- **Backend / BaaS:** Firebase (Authentication, Cloud Firestore) cung cấp hệ thống xác thực và cơ sở dữ liệu Realtime mạnh mẽ.
- **Frontend (Mobile App):** Flutter (Dart) phiên bản mới nhất.
- **State Management:** `flutter_riverpod` giúp quản lý trạng thái ứng dụng một cách hiệu quả, an toàn, dễ test.
- **Routing:** `go_router` hỗ trợ điều hướng trang hiện đại, hỗ trợ deep-link.

### 4.2. TỔ CHỨC MÃ NGUỒN FRONTEND
Ứng dụng sử dụng kiến trúc Feature-First (Chia theo tính năng), giúp mã nguồn dễ đọc, dễ bảo trì và mở rộng:
```text
lib/
├── features/
│   ├── auth/          # Xử lý Đăng nhập, Đăng ký
│   ├── expenses/      # Quản lý giao dịch chi tiêu
│   ├── groups/        # Quản lý nhóm (Home screen)
│   └── settlement/    # Tính toán cấn trừ công nợ
├── firebase_options.dart # Cấu hình Firebase
└── main.dart          # Entry point của ứng dụng
```
Mỗi feature sẽ có cấu trúc bên trong gồm: `screens`, `providers`, `models`, `widgets`.

### 4.3. CÀI ĐẶT CHỨC NĂNG CỐT LÕI
**Thuật toán Quyết toán tối ưu (Greedy Algorithm for Debt Settlement):**
Khi tính toán cấn trừ công nợ, ứng dụng thực hiện các bước sau trong logic của Riverpod Provider:
1. Tính `Net Balance` (Số dư ròng) cho từng thành viên: `Balance = Tổng tiền đã trả hộ - Tổng tiền thực tiêu`.
2. Tách thành viên thành 2 nhóm: Nhóm Ghi Có (Balance > 0, những người cần nhận lại tiền) và Nhóm Ghi Nợ (Balance < 0, những người cần trả tiền).
3. Lặp qua 2 danh sách, lấy người nợ nhiều nhất bù cho người cần nhận nhiều nhất. Ghi nhận giao dịch này và giảm trừ Balance của cả 2.
4. Quá trình lặp lại cho đến khi tất cả Balance bằng 0. Kết quả thu được là danh sách các giao dịch thanh toán tinh gọn nhất.

---

## CHƯƠNG 5: THỬ NGHIỆM VÀ TRIỂN KHAI

### 5.1. MÔI TRƯỜNG THỬ NGHIỆM
- **Phần cứng:** Thử nghiệm trực tiếp trên máy ảo Android Emulator (Pixel 6 API 34) và thiết bị thật (iPhone 13, Samsung Galaxy S23).
- **Mạng:** Kiểm thử trên cả môi trường Wifi ổn định và môi trường mạng 3G/4G chập chờn để đánh giá khả năng hoạt động offline-first của Firebase Firestore (Local Cache).

### 5.2. CÁC KỊCH BẢN THỬ NGHIỆM VÀ ĐÁNH GIÁ
**Kịch bản 1: Luồng tạo nhóm và thêm chi tiêu**
- *Mô tả:* Người dùng A tạo nhóm "Du lịch Đà Lạt", mời người dùng B. A thêm một khoản chi "Tiền xe" 500.000đ, A trả tiền, chia đều cho A và B.
- *Kết quả mong đợi:* Nhóm được tạo thành công, dữ liệu chi tiêu hiển thị ngay lập tức trên máy của B (nhờ realtime). Hệ thống ghi nhận B nợ A 250.000đ.
- *Kết quả thực tế:* Pass 100%. Giao diện cập nhật tức thời không cần pull-to-refresh.

**Kịch bản 2: Kiểm tra tính đúng đắn của Thuật toán Quyết toán**
- *Mô tả:* Nhóm 3 người A, B, C. A trả 300k (chia cho A,B,C). B trả 150k (chia cho B,C). 
- *Kết quả mong đợi:* Hệ thống tính toán chính xác: B cần trả A 25k, C cần trả A 175k (hoặc phương án tương đương số tiền).
- *Kết quả thực tế:* Pass 100%. Thuật toán đối trừ hoạt động chính xác và hiển thị danh sách thanh toán rõ ràng, dễ hiểu.

---

## KẾT LUẬN

**1. Kết quả đạt được**
Đồ án đã nghiên cứu và phát triển thành công Ứng dụng "Quản Lý Chi Tiêu Theo Nhóm", giải quyết triệt để bài toán tính toán chi phí, cấn trừ công nợ phức tạp trong các hoạt động đội nhóm. 
- Ứng dụng hoạt động mượt mà trên nhiều nền tảng nhờ sức mạnh của Flutter.
- Áp dụng thành công các công nghệ hiện đại như Riverpod và Firebase Firestore.
- Giao diện thân thiện, giải quyết đúng nhu cầu thực tế.

**2. Hạn chế còn tồn tại**
- Chưa hỗ trợ tính năng tự động trích xuất dữ liệu từ hóa đơn giấy (OCR) hoặc quét mã QR thanh toán để tự động tạo khoản chi.
- Chức năng thống kê (Biểu đồ) chưa thực sự phong phú và đa dạng.
- Hạn chế khi không có mạng (dù có cache nhưng thao tác đồng bộ thành viên mới cần kết nối mạng).

**3. Hướng phát triển tương lai**
- Tích hợp AI/OCR để tự động đọc thông tin từ ảnh chụp hóa đơn (hóa đơn nhà hàng, siêu thị) và tự động chia tiền theo từng món ăn.
- Tích hợp Deep-link chia sẻ mã QR hoặc link để mời thành viên tham gia nhóm nhanh chóng.
- Liên kết với các ví điện tử, ứng dụng ngân hàng để hỗ trợ chuyển khoản thanh toán trực tiếp từ ứng dụng.
- Đa ngôn ngữ và hỗ trợ chuyển đổi đa tiền tệ (Currency Converter) cho các chuyến du lịch nước ngoài.

---
*Hết báo cáo.*
