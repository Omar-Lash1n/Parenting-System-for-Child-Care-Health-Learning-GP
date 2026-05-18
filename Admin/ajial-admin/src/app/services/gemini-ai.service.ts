import { Injectable, inject } from '@angular/core';
import { HttpBackend, HttpClient } from '@angular/common/http';
import { Observable, map, catchError, throwError } from 'rxjs';
import { AiGeneratedQuestion } from '../models/daily-question.model';

const GEMINI_API_KEY = 'AIzaSyA_DrAPfmmLquHC-w203uc5O6gObnmEgeY';
const GEMINI_ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`;

const RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    questionText: { type: 'STRING' },
    options: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          optionText: { type: 'STRING' },
          isCorrect: { type: 'BOOLEAN' }
        },
        required: ['optionText', 'isCorrect']
      },
      minItems: 4,
      maxItems: 4
    },
    starsReward: { type: 'INTEGER', minimum: 1, maximum: 5 }
  },
  required: ['questionText', 'options', 'starsReward']
};

const GENERATION_PROMPT = `أنت خبير في تربية الأطفال ورعايتهم. أنشئ سؤالاً تفاعلياً باللغة العربية موجهاً للوالدين في تطبيق رعاية الأطفال "أجيال".

الشروط:
- اختر موضوعاً من: تربية الأطفال، الرعاية الصحية، التغذية، النمو والتطور، التعليم والتحفيز، السلامة.
- ضع 4 خيارات واضحة ومنطقية، خيار واحد فقط صحيح.
- تأكد من أن الخيارات الخاطئة معقولة وليست واضحة الخطأ.
- المكافأة من 1 إلى 5 نجوم حسب صعوبة السؤال (1 = سهل، 5 = صعب).`;

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
}

@Injectable({ providedIn: 'root' })
export class GeminiAiService {
  // Uses HttpBackend directly to bypass all HTTP interceptors (auth header must not reach Google's API)
  private http: HttpClient;

  constructor() {
    const backend = inject(HttpBackend);
    this.http = new HttpClient(backend);
  }

  generate(): Observable<AiGeneratedQuestion> {
    const requestBody = {
      contents: [{ parts: [{ text: GENERATION_PROMPT }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        responseSchema: RESPONSE_SCHEMA
      }
    };

    return this.http.post<GeminiResponse>(GEMINI_ENDPOINT, requestBody).pipe(
      map((res) => {
        const text = res.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!text) {
          throw new Error('استجابة فارغة من نموذج الذكاء الاصطناعي');
        }
        return JSON.parse(text) as AiGeneratedQuestion;
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
        if (httpErr.status === 400) {
          return throwError(() => new Error('طلب غير صالح. تحقق من إعدادات نموذج الذكاء الاصطناعي.'));
        }
        return throwError(() => new Error('حدث خطأ أثناء الاتصال بنموذج الذكاء الاصطناعي. حاول مرة أخرى.'));
      })
    );
  }
}
