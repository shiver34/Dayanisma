# Dayanışma

Dayanışma, sağlık sorunu yaşayan bireylerin benzer deneyimlere sahip kişilerle iletişim kurmasını, destek almasını ve deneyimlerini paylaşmasını amaçlayan Flutter tabanlı bir mobil uygulamadır.

## Projenin Amacı

Bu projenin amacı, sağlık sürecinde kendini yalnız hisseden kullanıcıların güvenli bir topluluk ortamında bir araya gelmesini sağlamaktır. Kullanıcılar hastalık kategorilerine göre forumlara katılabilir, konu açabilir, cevap yazabilir ve diğer kullanıcıların deneyimlerinden faydalanabilir.

Ayrıca uygulama içerisinde diyabet risk hesaplama özelliği bulunmaktadır. Bu özellik, kullanıcının sağlık bilgilerini kullanarak eğitilmiş bir TensorFlow Lite modeli ile yaklaşık diyabet risk tahmini yapar.

## Kullanılan Teknolojiler

- Flutter
- Dart
- Supabase
- Supabase Auth
- Supabase Database
- Supabase Storage
- TensorFlow Lite
- tflite_flutter
- SharedPreferences
- Cached Network Image

## Özellikler

- Kullanıcı kayıt olma ve giriş yapma
- Profil bilgilerini görüntüleme ve düzenleme
- Sağlık kategorilerini listeleme
- Alt kategorilere göre forumlara erişme
- Forum konusu oluşturma
- Konulara cevap yazma
- Konu ve cevap beğenme
- Destek talebi arayüzü
- Diyabet risk hesaplama
- Onboarding ekranları

## Diyabet Risk Tahmini

Projede diyabet risk tahmini için eğitilmiş bir makine öğrenmesi modeli kullanılmıştır. Model, TensorFlow Lite formatına dönüştürülerek uygulamaya entegre edilmiştir.

Modelin kullandığı başlıca veriler:

- Cinsiyet
- Yaş
- Hipertansiyon durumu
- Kalp hastalığı durumu
- Sigara kullanım geçmişi
- BMI / VKİ
- HbA1c seviyesi
- Kan şekeri seviyesi

Kullanıcıdan alınan bilgiler modele uygun hale getirilir, normalize edilir ve model 0 ile 1 arasında bir risk skoru üretir. Bu skor belirlenen eşik değerine göre düşük veya yüksek risk olarak kullanıcıya gösterilir.

## Veritabanı Yapısı

Projede Supabase kullanılmıştır. Kullanılan temel tablolar:

- profiles
- categories
- subcategories
- forum_threads
- forum_posts
- forum_thread_likes
- forum_post_likes

Kategori görselleri için Supabase Storage kullanılmıştır.

## Proje Yapısı

```text
lib/
 ├── main.dart
 ├── onboarding/
 ├── features/
 │   ├── auth/
 │   ├── categories/
 │   ├── forum/
 │   ├── profile/
 │   ├── support/
 │   ├── about/
 │   └── diabetes/
 └── widgets/

assets/
 └── ml/
     ├── diabetes_model.tflite
     └── diabetes_metadata.json
