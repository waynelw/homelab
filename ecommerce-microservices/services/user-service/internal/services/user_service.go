package services

import (
	"errors"
	"time"

	"user-service/internal/models"
	"user-service/internal/repository"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserService interface {
	CreateUser(req *models.CreateUserRequest) (*models.UserResponse, error)
	GetUser(id uuid.UUID) (*models.UserResponse, error)
	UpdateUser(id uuid.UUID, req *models.UpdateUserRequest) (*models.UserResponse, error)
	DeleteUser(id uuid.UUID) error
	Register(req *models.CreateUserRequest) (*models.LoginResponse, error)
	Login(req *models.LoginRequest) (*models.LoginResponse, error)
	RefreshToken(refreshToken string) (*models.LoginResponse, error)
}

type userService struct {
	userRepo  repository.UserRepository
	jwtSecret string
}

func NewUserService(userRepo repository.UserRepository) UserService {
	return &userService{
		userRepo:  userRepo,
		jwtSecret: "your-secret-key", // 应该从配置中读取
	}
}

func (s *userService) CreateUser(req *models.CreateUserRequest) (*models.UserResponse, error) {
	// 检查邮箱是否已存在
	_, err := s.userRepo.GetByEmail(req.Email)
	if err == nil {
		return nil, errors.New("email already exists")
	}

	// 检查用户名是否已存在
	_, err = s.userRepo.GetByUsername(req.Username)
	if err == nil {
		return nil, errors.New("username already exists")
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	// 创建用户
	user := &models.User{
		Email:     req.Email,
		Username:  req.Username,
		Password:  string(hashedPassword),
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Phone:     req.Phone,
		Address:   req.Address,
		IsActive:  true,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	return user.ToResponse(), nil
}

func (s *userService) GetUser(id uuid.UUID) (*models.UserResponse, error) {
	user, err := s.userRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	return user.ToResponse(), nil
}

func (s *userService) UpdateUser(id uuid.UUID, req *models.UpdateUserRequest) (*models.UserResponse, error) {
	user, err := s.userRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	// 更新字段
	if req.FirstName != "" {
		user.FirstName = req.FirstName
	}
	if req.LastName != "" {
		user.LastName = req.LastName
	}
	if req.Phone != "" {
		user.Phone = req.Phone
	}
	if req.Address != "" {
		user.Address = req.Address
	}

	if err := s.userRepo.Update(user); err != nil {
		return nil, err
	}

	return user.ToResponse(), nil
}

func (s *userService) DeleteUser(id uuid.UUID) error {
	return s.userRepo.Delete(id)
}

func (s *userService) Register(req *models.CreateUserRequest) (*models.LoginResponse, error) {
	// 创建用户
	userResp, err := s.CreateUser(req)
	if err != nil {
		return nil, err
	}

	// 获取完整用户信息
	user, err := s.userRepo.GetByID(userResp.ID)
	if err != nil {
		return nil, err
	}

	// 生成 JWT token
	accessToken, refreshToken, expiresIn, err := s.generateTokens(user.ID.String())
	if err != nil {
		return nil, err
	}

	return &models.LoginResponse{
		User:         user.ToResponse(),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
	}, nil
}

func (s *userService) Login(req *models.LoginRequest) (*models.LoginResponse, error) {
	// 获取用户
	user, err := s.userRepo.GetByEmail(req.Email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid credentials")
	}

	// 检查用户是否激活
	if !user.IsActive {
		return nil, errors.New("account is deactivated")
	}

	// 生成 JWT token
	accessToken, refreshToken, expiresIn, err := s.generateTokens(user.ID.String())
	if err != nil {
		return nil, err
	}

	return &models.LoginResponse{
		User:         user.ToResponse(),
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    expiresIn,
	}, nil
}

func (s *userService) RefreshToken(refreshToken string) (*models.LoginResponse, error) {
	// 验证 refresh token
	token, err := jwt.Parse(refreshToken, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.jwtSecret), nil
	})

	if err != nil || !token.Valid {
		return nil, errors.New("invalid refresh token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	userIDStr, ok := claims["user_id"].(string)
	if !ok {
		return nil, errors.New("invalid user id in token")
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, errors.New("invalid user id format")
	}

	// 获取用户
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	// 生成新的 token
	accessToken, newRefreshToken, expiresIn, err := s.generateTokens(user.ID.String())
	if err != nil {
		return nil, err
	}

	return &models.LoginResponse{
		User:         user.ToResponse(),
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    expiresIn,
	}, nil
}

func (s *userService) generateTokens(userID string) (string, string, int64, error) {
	// Access token (15 分钟过期)
	accessClaims := jwt.MapClaims{
		"user_id": userID,
		"type":    "access",
		"exp":     time.Now().Add(time.Minute * 15).Unix(),
	}

	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenString, err := accessToken.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return "", "", 0, err
	}

	// Refresh token (7 天过期)
	refreshClaims := jwt.MapClaims{
		"user_id": userID,
		"type":    "refresh",
		"exp":     time.Now().Add(time.Hour * 24 * 7).Unix(),
	}

	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString([]byte(s.jwtSecret))
	if err != nil {
		return "", "", 0, err
	}

	return accessTokenString, refreshTokenString, 15 * 60, nil
}
