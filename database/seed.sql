USE QuanLyChiTieuDB;
GO

-- 1. Insert Users
INSERT INTO Users (Id, DisplayName, Email, PasswordHash) VALUES
('user_1', N'Nguyễn Văn A', 'nguyenvana@example.com', '123456'),
('user_2', N'Trần Thị B', 'tranthib@example.com', '123456');
GO

-- 2. Insert Groups
INSERT INTO Groups (Id, Name, CreatedAt, CreatedBy, Budget, IsPersonal) VALUES
('group_personal_1', N'Cá nhân', GETDATE(), 'user_1', 10000000, 1),
('group_shared_1', N'Nhóm Du Lịch', GETDATE(), 'user_1', 50000000, 0);
GO

-- 3. Insert GroupMembers
INSERT INTO GroupMembers (GroupId, UserId) VALUES
('group_personal_1', 'user_1'),
('group_shared_1', 'user_1'),
('group_shared_1', 'user_2');
GO

-- 4. Insert Expenses
INSERT INTO Expenses (Id, GroupId, Description, Amount, Category, PaidBy, Date, Type, IsConfirmed, Currency, ExchangeRate) VALUES
('exp_1', 'group_personal_1', N'Ăn sáng', 50000, N'Ăn uống', 'user_1', GETDATE(), 'expense', 1, 'VND', 1.0),
('exp_2', 'group_personal_1', N'Đổ xăng', 100000, N'Đi lại', 'user_1', GETDATE(), 'expense', 1, 'VND', 1.0),
('exp_3', 'group_shared_1', N'Vé máy bay', 2500000, N'Du lịch', 'user_1', GETDATE(), 'expense', 1, 'VND', 1.0),
('exp_4', 'group_shared_1', N'Đặt phòng khách sạn', 3000000, N'Du lịch', 'user_2', GETDATE(), 'expense', 1, 'VND', 1.0);
GO

-- 5. Insert SavingsGoals
INSERT INTO SavingsGoals (Id, UserId, Title, TargetAmount, CurrentAmount, TargetDate, Icon, Color) VALUES
('sav_1', 'user_1', N'Mua Macbook', 40000000, 15000000, DATEADD(month, 6, GETDATE()), 'savings', '#FF5722');
GO

-- 6. Insert RecurringExpenses
INSERT INTO RecurringExpenses (Id, GroupId, Description, Amount, Category, PaidBy, Frequency, NextRunDate, IsActive) VALUES
('rec_1', 'group_personal_1', N'Tiền mạng Internet', 250000, N'Hóa đơn', 'user_1', 'monthly', DATEADD(month, 1, GETDATE()), 1);
GO

-- 7. Insert ChatMessages
INSERT INTO ChatMessages (Id, UserId, MessageText, IsUser, CreatedAt) VALUES
('chat_1', 'user_1', N'Tháng này tôi tiêu nhiều quá không?', 1, GETDATE()),
('chat_2', 'user_1', N'Bạn đã chi 150,000 VND trong nhóm cá nhân. Hiện tại chưa thấy dấu hiệu lãng phí lớn, hãy tiếp tục duy trì nhé!', 0, GETDATE());
GO

-- 8. Bảng Audit (Ghi log các khoản chi tiêu bị xóa)
CREATE TABLE DeletedExpensesAudit (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    ExpenseId NVARCHAR(128),
    DeletedBy NVARCHAR(128),
    Amount FLOAT,
    DeletedAt DATETIME2 DEFAULT GETDATE()
);
GO

-- 9. Trigger: Tự động ghi log khi có giao dịch chi tiêu bị xóa
CREATE TRIGGER trg_AfterDeleteExpense
ON Expenses
AFTER DELETE
AS
BEGIN
    INSERT INTO DeletedExpensesAudit (ExpenseId, DeletedBy, Amount)
    SELECT Id, PaidBy, Amount FROM deleted;
END;
GO

-- 10. Trigger: Cảnh báo và ngăn chặn nhập khoản chi tiêu với số tiền âm
CREATE TRIGGER trg_PreventNegativeExpense
ON Expenses
INSTEAD OF INSERT
AS
BEGIN
    -- Nếu có bản ghi nào có Amount <= 0 thì báo lỗi
    IF EXISTS (SELECT 1 FROM inserted WHERE Amount <= 0)
    BEGIN
        RAISERROR (N'Số tiền chi tiêu phải lớn hơn 0!', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO Expenses (Id, GroupId, Description, Amount, Category, PaidBy, ToUserId, Date, Type, IsConfirmed, Currency, OriginalAmount, ExchangeRate)
        SELECT Id, GroupId, Description, Amount, Category, PaidBy, ToUserId, Date, Type, IsConfirmed, Currency, OriginalAmount, ExchangeRate
        FROM inserted;
    END
END;
GO
