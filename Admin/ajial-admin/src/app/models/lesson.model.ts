export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  errors: string[] | null;
}

export interface LessonCategoryDto {
  id: string;
  nameAr: string;
  nameEn: string | null;
  orderIndex: number;
  isActive: boolean;
  lessonCount: number;
}

export interface CreateLessonCategoryRequest {
  nameAr: string;
  nameEn?: string | null;
  orderIndex: number;
}

export interface UpdateLessonCategoryRequest {
  nameAr: string;
  nameEn?: string | null;
  orderIndex: number;
  isActive: boolean;
}

export interface LessonAdminOptionDto {
  id: string;
  optionText: string;
  isCorrect: boolean;
  orderIndex: number;
}

export interface LessonAdminQuestionDto {
  id: string;
  questionText: string;
  starsReward: number;
  orderIndex: number;
  options: LessonAdminOptionDto[];
}

export interface LessonAdminDetailDto {
  id: string;
  categoryId: string;
  categoryNameAr: string;
  titleAr: string;
  contentAr: string;
  imageUrl: string | null;
  videoUrl: string | null;
  isActive: boolean;
  totalStarsReward: number;
  totalReads: number;
  totalCompletions: number;
  questions: LessonAdminQuestionDto[];
  createdAt: string;
  updatedAt: string | null;
}

export interface LessonAdminListDto {
  id: string;
  titleAr: string;
  imageUrl: string | null;
  categoryNameAr: string;
  isActive: boolean;
  questionsCount: number;
  totalStarsReward: number;
  totalReads: number;
  totalCompletions: number;
  createdAt: string;
}

export interface CreateLessonQuestionOptionRequest {
  optionText: string;
  isCorrect: boolean;
}

export interface CreateLessonQuestionRequest {
  questionText: string;
  starsReward: number;
  options: CreateLessonQuestionOptionRequest[];
}

export interface CreateLessonRequest {
  categoryId: string;
  titleAr: string;
  contentAr: string;
  imageUrl?: string | null;
  videoUrl?: string | null;
  isActive: boolean;
  questions: CreateLessonQuestionRequest[];
}

export interface UpdateLessonRequest {
  categoryId: string;
  titleAr: string;
  contentAr: string;
  imageUrl?: string | null;
  videoUrl?: string | null;
  questions: CreateLessonQuestionRequest[];
}

export interface AiGeneratedLesson {
  titleAr: string;
  contentAr: string;
  questions: AiGeneratedLessonQuestion[];
}

export interface AiGeneratedLessonQuestion {
  questionText: string;
  starsReward: number;
  options: CreateLessonQuestionOptionRequest[];
}
