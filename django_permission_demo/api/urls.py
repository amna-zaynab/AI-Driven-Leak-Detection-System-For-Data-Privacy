from django.conf import settings
from django.urls import path
from django.conf.urls.static import static
from . import views

urlpatterns = [
    path('permissions/<str:username>/', views.user_permissions, name='user-permissions'),
    path('api/submit_permissions/', views.submit_permissions, name='submit-permissions'),
    path('api/get_privacy_score/', views.get_privacy_score, name='get-privacy-score'),
    path('', views.log, name='log'),
    path('logpost', views.logpost, name='logpost'),
    path('logout', views.logout_view, name='logout'),
    path('adminhome', views.adminhome, name='adminhome'),
   path('forgotpassword', views.forgotpassword, name='forgotpassword'),
   path('forgotpasswordbuttonclick', views.forgotpasswordbuttonclick, name='forgotpasswordbuttonclick'),
   path('otp', views.otp, name='otp'),
   path('otpbuttonclick', views.otpbuttonclick, name='otpbuttonclick'),
   path('forgotpswdpswed', views.forgotpswdpswed, name='forgotpswdpswed'),
   path('forgotpswdpswedbuttonclick', views.forgotpswdpswedbuttonclick, name='forgotpswdpswedbuttonclick'),
   path('change_password', views.change_password, name='change_password'),
    path('change_password_post', views.change_password_post, name='change_password_post'),  

    # APK upload and permission extraction endpoint
    path('upload_apk/', views.upload_apk, name='upload_apk'),
    path('get_apk_list/', views.get_apk_list, name='get_apk_list'),
    path('delete_apk/', views.delete_apk, name='delete_apk'),
    path('api/get_privacy_score/', views.get_privacy_score),
    path('api/get_scanned_apps/', views.get_scanned_apps, name='get_scanned_apps'),
    
    # Breach detection endpoints
    path('api/store_breach/', views.store_breach, name='store_breach'),
    path('api/get_breaches/<str:email>/', views.get_breaches, name='get_breaches'),
    path('api/get_user_breaches/', views.get_user_breaches, name='get_user_breaches'),
    
    # Phone breach detection endpoints
    path('api/store_phone_breach/', views.store_phone_breach, name='store_phone_breach'),
    path('api/get_phone_breaches/<str:phone>/', views.get_phone_breaches, name='get_phone_breaches'),
    path('api/get_user_phone_breaches/', views.get_user_phone_breaches, name='get_user_phone_breaches'),
    
    # Phishing URL detection endpoints
    path('api/check_phishing_url/', views.check_phishing_url, name='check_phishing_url'),
    path('api/get_phishing_history/', views.get_phishing_history, name='get_phishing_history'),
    path('api/get_phishing_url_detail/<int:url_id>/', views.get_phishing_url_detail, name='get_phishing_url_detail'),
    
    # User registration endpoint
    path('api/register/', views.register, name='register'),
    
    # User login endpoint
    path('api/login/', views.login1, name='login'),
    
    # Password breach detection endpoint
    path('api/check_password_breach/', views.check_password_breach, name='check_password_breach'),

]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
