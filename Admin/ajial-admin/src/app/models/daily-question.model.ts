export interface DailyQuestionOptionRequest {
  optionText: string;
  isCorrect: boolean;
}

export interface CreateDailyQuestionRequest {
  questionText: string;
  starsReward: number;
  isActive: boolean;
  options: DailyQuestionOptionRequest[];
}

export interface UpdateDailyQuestionRequest {
  questionText: string;
  starsReward: number;
  isActive: boolean;
  options: DailyQuestionOptionRequest[];
}

export interface DailyQuestionOptionResponse {
  id: string;
  optionText: string;
  isCorrect: boolean;
  orderIndex: number;
}

export interface DailyQuestionAdminDto {
  id: string;
  questionText: string;
  starsReward: number;
  isActive: boolean;
  options: DailyQuestionOptionResponse[];
  totalAnswers: number;
  correctAnswers: number;
  createdAt: string;
}

export interface DailyQuestionListDto {
  id: string;
  questionText: string;
  starsReward: number;
  isActive: boolean;
  totalAnswers: number;
  correctAnswers: number;
  createdAt: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  errors: string[] | null;
}

export interface AiGeneratedQuestion {
  questionText: string;
  options: DailyQuestionOptionRequest[];
  starsReward: number;
}
