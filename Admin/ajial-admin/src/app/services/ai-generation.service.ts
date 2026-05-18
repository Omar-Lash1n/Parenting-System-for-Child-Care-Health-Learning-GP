import { Injectable, inject } from '@angular/core';
import { HttpBackend, HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { AiGeneratedQuestion } from '../models/daily-question.model';

// ⚠️ IMPORTANT: Never commit real API keys. Store this in environment variables.
// For local dev, create src/environments/environment.ts with your key.
const OPENAI_API_KEY = (typeof window !== 'undefined' && (window as any).__GROQ_API_KEY__)
  ? (window as any).__GROQ_API_KEY__
  : 'YOUR_GROQ_API_KEY_HERE';
const OPENAI_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

const SYSTEM_PROMPT = `أنت خبير في تربية الأطفال ورعايتهم. مهمتك إنشاء أسئلة تفاعلية باللغة العربية للوالدين في تطبيق رعاية الأطفال "أجيال".

قواعد الإجابة:
- أجب دائماً بـ JSON فقط بدون أي نص إضافي.
- الهيكل المطلوب:
{
  "questionText": "نص السؤال",
  "options": [
    { "optionText": "الخيار الأول", "isCorrect": false },
    { "optionText": "الخيار الثاني", "isCorrect": true },
    { "optionText": "الخيار الثالث", "isCorrect": false },
    { "optionText": "الخيار الرابع", "isCorrect": false }
  ],
  "starsReward": 3
}`;

const USER_PROMPT = `أنشئ سؤالاً تفاعلياً واحداً باللغة العربية يخص أحد هذه المجالات: تربية الأطفال، الرعاية الصحية، التغذية، النمو والتطور، التعليم والتحفيز، السلامة.

الشروط:
- 4 خيارات واضحة ومنطقية.
- خيار واحد فقط صحيح (isCorrect: true).
- الخيارات الخاطئة معقولة وليست واضحة الخطأ.
- starsReward من 1 إلى 5 حسب الصعوبة.`;

interface OpenAiResponse {
  choices?: Array<{
    message?: { content?: string };
  }>;
  error?: { message?: string; code?: string };
}

@Injectable({ providedIn: 'root' })
export class AiGenerationService {
  // Uses HttpBackend directly — bypasses all Angular interceptors so no app auth headers reach OpenAI
  private http: HttpClient;

  constructor() {
    const backend = inject(HttpBackend);
    this.http = new HttpClient(backend);
  }

  generate(): Observable<AiGeneratedQuestion> {
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
        return JSON.parse(content) as AiGeneratedQuestion;
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
