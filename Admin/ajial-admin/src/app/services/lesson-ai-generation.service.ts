import { Injectable, inject } from '@angular/core';
import { HttpBackend, HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { AiGeneratedLesson } from '../models/lesson.model';
import { environment } from '../../environments/environment';

const OPENAI_API_KEY = environment.groqApiKey;
const OPENAI_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

const SYSTEM_PROMPT = `أنت خبير في التربية ورعاية الأطفال. مهمتك إنشاء درس تربوي تعليمي باللغة العربية للوالدين في تطبيق "أجيال".

قواعد الإجابة:
- أجب دائماً بـ JSON فقط بدون أي نص إضافي.
- الهيكل المطلوب:
{
  "titleAr": "عنوان الدرس",
  "contentAr": "محتوى الدرس التفصيلي (فقرة من 150 إلى 300 كلمة)",
  "questions": [
    {
      "questionText": "نص السؤال",
      "starsReward": 3,
      "options": [
        { "optionText": "الخيار الأول", "isCorrect": false },
        { "optionText": "الخيار الثاني", "isCorrect": true },
        { "optionText": "الخيار الثالث", "isCorrect": false },
        { "optionText": "الخيار الرابع", "isCorrect": false }
      ]
    }
  ]
}`;

const USER_PROMPT = `أنشئ درساً تربوياً واحداً باللغة العربية في أحد هذه المجالات: التواصل العاطفي مع الطفل، الحدود والانضباط الإيجابي، التغذية والصحة، اللعب والتعلم، النوم والروتين اليومي، الذكاء العاطفي.

الشروط:
- عنوان واضح وجاذب.
- محتوى تفصيلي بين 150 و300 كلمة.
- سؤالان إلى ثلاثة أسئلة اختيارية، كل سؤال له 4 خيارات وإجابة صحيحة واحدة فقط.
- starsReward من 1 إلى 5 حسب صعوبة السؤال.`;

interface OpenAiResponse {
  choices?: Array<{
    message?: { content?: string };
  }>;
  error?: { message?: string; code?: string };
}

@Injectable({ providedIn: 'root' })
export class LessonAiGenerationService {
  private http: HttpClient;

  constructor() {
    const backend = inject(HttpBackend);
    this.http = new HttpClient(backend);
  }

  generate(): Observable<AiGeneratedLesson> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${OPENAI_API_KEY}`
    });

    const requestBody = {
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: USER_PROMPT }
      ],
      response_format: { type: 'json_object' },
      temperature: 0.8
    };

    return this.http.post<OpenAiResponse>(OPENAI_ENDPOINT, requestBody, { headers }).pipe(
      map((res) => {
        const content = res.choices?.[0]?.message?.content;
        if (!content) {
          throw new Error('استجابة فارغة من نموذج الذكاء الاصطناعي');
        }
        return JSON.parse(content) as AiGeneratedLesson;
      }),
      catchError((err: unknown) => {
        if (err instanceof SyntaxError) {
          return throwError(() => new Error('تعذر تحليل رد الذكاء الاصطناعي'));
        }
        if (err instanceof Error && err.message) {
          return throwError(() => err);
        }
        const httpErr = err as { status?: number };
        if (httpErr.status === 429) {
          return throwError(() => new Error('تم تجاوز حد الطلبات. حاول مرة أخرى بعد قليل.'));
        }
        if (httpErr.status === 401) {
          return throwError(() => new Error('مفتاح API غير صالح. تحقق من إعدادات الاتصال.'));
        }
        if (httpErr.status === 400) {
          return throwError(() => new Error('طلب غير صالح. حاول مرة أخرى.'));
        }
        return throwError(() => new Error('حدث خطأ أثناء الاتصال بنموذج الذكاء الاصطناعي. حاول مرة أخرى.'));
      })
    );
  }
}
