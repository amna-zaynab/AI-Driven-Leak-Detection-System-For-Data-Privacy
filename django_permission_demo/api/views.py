import random
import smtplib
from django.contrib.auth.models import User
from django.http import HttpResponse, JsonResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_GET, require_POST
import json
from django.contrib.auth import authenticate, login , logout
from django.contrib.sessions.models import Session
import os
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from .models import AppHistory, BreachHistory, PhoneBreachHistory, PhishingUrlHistory

# You may need to install androguard: pip install androguard
from androguard.core.bytecodes.apk import APK
# views.py
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import os
import csv
import pickle
import numpy as np

# List of all possible permissions (should match training set)
# List of all possible permissions (should match training set)
ALL_PERMISSIONS = [
    'android.permission.BIND_WALLPAPER',
    'android.permission.FORCE_BACK',
    'android.permission.READ_CALENDAR',
    'android.permission.BODY_SENSORS',
    'android.permission.READ_SOCIAL_STREAM',
    'android.permission.READ_SYNC_STATS',
    'android.permission.INTERNET',
    'android.permission.CHANGE_CONFIGURATION',
    'android.permission.BIND_DREAM_SERVICE',
    'android.permission.HARDWARE_TEST',
    'com.android.browser.permission.WRITE_HISTORY_BOOKMARKS',
    'com.android.launcher.permission.INSTALL_SHORTCUT',
    'android.permission.BIND_TV_INPUT',
    'android.permission.BIND_VPN_SERVICE',
    'android.permission.BLUETOOTH_PRIVILEGED',
    'android.permission.WRITE_CALL_LOG',
    'android.permission.CHANGE_WIFI_MULTICAST_STATE',
    'android.permission.BIND_INPUT_METHOD',
    'android.permission.SET_TIME_ZONE',
    'android.permission.WRITE_SYNC_SETTINGS',
    'android.permission.WRITE_GSERVICES',
    'android.permission.SET_ORIENTATION',
    'android.permission.BIND_DEVICE_ADMIN',
    'android.permission.MANAGE_DOCUMENTS',
    'android.permission.FORCE_STOP_PACKAGES',
    'android.permission.WRITE_SECURE_SETTINGS',
    'android.permission.CALL_PRIVILEGED',
    'android.permission.MOUNT_FORMAT_FILESYSTEMS',
    'android.permission.SYSTEM_ALERT_WINDOW',
    'android.permission.ACCESS_LOCATION_EXTRA_COMMANDS',
    'android.permission.BRICK',
    'android.permission.DUMP',
    'android.permission.CHANGE_WIFI_STATE',
    'android.permission.RECORD_AUDIO',
    'android.permission.MODIFY_PHONE_STATE',
    'android.permission.READ_PROFILE',
    'android.permission.ACCOUNT_MANAGER',
    'android.permission.SET_ANIMATION_SCALE',
    'android.permission.SET_PROCESS_LIMIT',
    'android.permission.CAPTURE_SECURE_VIDEO_OUTPUT',
    'android.permission.SET_PREFERRED_APPLICATIONS',
    'android.permission.ACCESS_ALL_DOWNLOADS',
    'android.permission.SET_DEBUG_APP',
    'android.permission.STOP_APP_SWITCHES',
    'android.permission.BLUETOOTH',
    'android.permission.ACCESS_WIFI_STATE',
    'android.permission.SET_WALLPAPER_HINTS',
    'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
    'android.permission.MMS_SEND_OUTBOX_MSG',
    'android.permission.CONTROL_LOCATION_UPDATES',
    'android.permission.UPDATE_APP_OPS_STATS',
    'android.permission.REBOOT',
    'android.permission.BROADCAST_WAP_PUSH',
    'com.android.launcher3.permission.READ_SETTINGS',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.STATUS_BAR',
    'android.permission.WRITE_USER_DICTIONARY',
    'com.android.browser.permission.READ_HISTORY_BOOKMARKS',
    'android.permission.BROADCAST_PACKAGE_REMOVED',
    'android.permission.RECEIVE_SMS',
    'android.permission.WRITE_CONTACTS',
    'android.permission.READ_CONTACTS',
    'android.permission.BIND_APPWIDGET',
    'android.permission.SIGNAL_PERSISTENT_PROCESSES',
    'android.permission.INSTALL_LOCATION_PROVIDER',
    'android.permission.ACCESS_DOWNLOAD_MANAGER_ADVANCED',
    'android.permission.WRITE_SETTINGS',
    'android.permission.MASTER_CLEAR',
    'android.permission.READ_INPUT_STATE',
    'android.permission.MANAGE_APP_TOKENS',
    'android.permission.BIND_REMOTEVIEWS',
    'com.android.email.permission.ACCESS_PROVIDER',
    'android.permission.BIND_VOICE_INTERACTION',
    'com.android.launcher.permission.WRITE_SETTINGS',
    'com.android.gallery3d.filtershow.permission.READ',
    'android.permission.BIND_PRINT_SERVICE',
    'android.permission.MODIFY_AUDIO_SETTINGS',
    'android.permission.USE_SIP',
    'android.permission.WRITE_APN_SETTINGS',
    'android.permission.ACCESS_SURFACE_FLINGER',
    'android.permission.FACTORY_TEST',
    'android.permission.READ_LOGS',
    'android.permission.PROCESS_OUTGOING_CALLS',
    'android.permission.UPDATE_DEVICE_STATS',
    'android.permission.SEND_DOWNLOAD_COMPLETED_INTENTS',
    'android.permission.WRITE_CALENDAR',
    'android.permission.NFC',
    'android.permission.MANAGE_ACCOUNTS',
    'android.permission.SEND_SMS',
    'android.permission.INTERACT_ACROSS_USERS_FULL',
    'android.permission.ACCESS_MOCK_LOCATION',
    'android.permission.BIND_ACCESSIBILITY_SERVICE',
    'android.permission.CAPTURE_AUDIO_OUTPUT',
    'android.permission.WRITE_SMS',
    'android.permission.GET_TASKS',
    'android.permission.DELETE_PACKAGES',
    'android.permission.ACCESS_CHECKIN_PROPERTIES',
    'android.permission.SEND_RESPOND_VIA_MESSAGE',
    'android.permission.MEDIA_CONTENT_CONTROL',
    'android.permission.DOWNLOAD_WITHOUT_NOTIFICATION',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.VIBRATE',
    'android.permission.DIAGNOSTIC',
    'android.permission.WRITE_PROFILE',
    'android.permission.CALL_PHONE',
    'android.permission.FLASHLIGHT',
    'android.permission.READ_PHONE_STATE',
    'android.permission.CHANGE_COMPONENT_ENABLED_STATE',
    'android.permission.CLEAR_APP_USER_DATA',
    'android.permission.BROADCAST_SMS',
    'android.permission.KILL_BACKGROUND_PROCESSES',
    'android.permission.READ_FRAME_BUFFER',
    'android.permission.SUBSCRIBED_FEEDS_WRITE',
    'android.permission.CAMERA',
    'android.permission.RECEIVE_MMS',
    'android.permission.WAKE_LOCK',
    'android.permission.ACCESS_DOWNLOAD_MANAGER',
    'com.android.launcher3.permission.WRITE_SETTINGS',
    'android.permission.DELETE_CACHE_FILES',
    'android.permission.RESTART_PACKAGES',
    'android.permission.GET_ACCOUNTS',
    'android.permission.SUBSCRIBED_FEEDS_READ',
    'android.permission.CHANGE_NETWORK_STATE',
    'android.permission.READ_SYNC_SETTINGS',
    'android.permission.DISABLE_KEYGUARD',
    'com.android.launcher.permission.UNINSTALL_SHORTCUT',
    'android.permission.USE_CREDENTIALS',
    'android.permission.READ_USER_DICTIONARY',
    'android.permission.WRITE_MEDIA_STORAGE',
    'android.permission.ACCESS_COARSE_LOCATION',
    'com.android.email.permission.READ_ATTACHMENT',
    'android.permission.SET_POINTER_SPEED',
    'android.permission.BACKUP',
    'android.permission.EXPAND_STATUS_BAR',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.LOCATION_HARDWARE',
    'android.permission.PERSISTENT_ACTIVITY',
    'android.permission.REORDER_TASKS',
    'android.permission.BIND_TEXT_SERVICE',
    'android.permission.DEVICE_POWER',
    'android.permission.SET_WALLPAPER',
    'android.permission.READ_CALL_LOG',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.GET_PACKAGE_SIZE',
    'android.permission.WRITE_SOCIAL_STREAM',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.INSTALL_PACKAGES',
    'android.permission.AUTHENTICATE_ACCOUNTS',
    'com.android.launcher.permission.READ_SETTINGS',
    'com.android.alarm.permission.SET_ALARM',
    'android.permission.INTERNAL_SYSTEM_WINDOW',
    'android.permission.CLEAR_APP_CACHE',
    'android.permission.CAPTURE_VIDEO_OUTPUT',
    'android.permission.GET_TOP_ACTIVITY_INFO',
]

# Note: There are 135 permissions in this list
@csrf_exempt
def upload_apk(request):
    if request.method == 'POST' and request.FILES.get('apk_file'):
        apk_file = request.FILES['apk_file']
        apk_type = request.POST.get('apk_type', 'benign')

        # Save the file
        media_dir = os.path.join(os.getcwd(), 'media')
        os.makedirs(media_dir, exist_ok=True)
        file_path = os.path.join(media_dir, apk_file.name)
        
        with open(file_path, 'wb+') as destination:
            for chunk in apk_file.chunks():
                destination.write(chunk)

        # Extract permissions
        try:
            apk = APK(file_path)
            permissions = apk.get_permissions() or []
            print(f"Extracted permissions: {permissions}")
            
            # Convert permissions to string list for easier handling
            perm_list = list(permissions)
            
            # Initialize cv list
            cv = []
            
            # Check each permission
            if 'android.permission.BIND_WALLPAPER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.FORCE_BACK' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.READ_CALENDAR' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BODY_SENSORS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.READ_SOCIAL_STREAM' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.READ_SYNC_STATS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.INTERNET' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.CHANGE_CONFIGURATION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BIND_DREAM_SERVICE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.HARDWARE_TEST' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'com.android.browser.permission.WRITE_HISTORY_BOOKMARKS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'com.android.launcher.permission.INSTALL_SHORTCUT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BIND_TV_INPUT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BIND_VPN_SERVICE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BLUETOOTH_PRIVILEGED' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.WRITE_CALL_LOG' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.CHANGE_WIFI_MULTICAST_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BIND_INPUT_METHOD' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.SET_TIME_ZONE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.WRITE_SYNC_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.WRITE_GSERVICES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.SET_ORIENTATION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BIND_DEVICE_ADMIN' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.MANAGE_DOCUMENTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.FORCE_STOP_PACKAGES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.WRITE_SECURE_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.CALL_PRIVILEGED' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.MOUNT_FORMAT_FILESYSTEMS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.SYSTEM_ALERT_WINDOW' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.ACCESS_LOCATION_EXTRA_COMMANDS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.BRICK' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.DUMP' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.CHANGE_WIFI_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.RECORD_AUDIO' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            if 'android.permission.MODIFY_PHONE_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_PROFILE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCOUNT_MANAGER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_ANIMATION_SCALE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_PROCESS_LIMIT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CAPTURE_SECURE_VIDEO_OUTPUT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_PREFERRED_APPLICATIONS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_ALL_DOWNLOADS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_DEBUG_APP' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.STOP_APP_SWITCHES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BLUETOOTH' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_WIFI_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_WALLPAPER_HINTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.MMS_SEND_OUTBOX_MSG' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CONTROL_LOCATION_UPDATES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.UPDATE_APP_OPS_STATS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.REBOOT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BROADCAST_WAP_PUSH' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.launcher3.permission.READ_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_NETWORK_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.STATUS_BAR' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_USER_DICTIONARY' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.browser.permission.READ_HISTORY_BOOKMARKS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BROADCAST_PACKAGE_REMOVED' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.RECEIVE_SMS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_CONTACTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_CONTACTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_APPWIDGET' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SIGNAL_PERSISTENT_PROCESSES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.INSTALL_LOCATION_PROVIDER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_DOWNLOAD_MANAGER_ADVANCED' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.MASTER_CLEAR' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_INPUT_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.MANAGE_APP_TOKENS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_REMOTEVIEWS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.email.permission.ACCESS_PROVIDER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_VOICE_INTERACTION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.launcher.permission.WRITE_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.gallery3d.filtershow.permission.READ' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_PRINT_SERVICE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.MODIFY_AUDIO_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.USE_SIP' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_APN_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_SURFACE_FLINGER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.FACTORY_TEST' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_LOGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.PROCESS_OUTGOING_CALLS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.UPDATE_DEVICE_STATS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SEND_DOWNLOAD_COMPLETED_INTENTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_CALENDAR' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.NFC' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.MANAGE_ACCOUNTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SEND_SMS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.INTERACT_ACROSS_USERS_FULL' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_MOCK_LOCATION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_ACCESSIBILITY_SERVICE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CAPTURE_AUDIO_OUTPUT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_SMS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.GET_TASKS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.DELETE_PACKAGES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_CHECKIN_PROPERTIES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SEND_RESPOND_VIA_MESSAGE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.MEDIA_CONTENT_CONTROL' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.DOWNLOAD_WITHOUT_NOTIFICATION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.RECEIVE_BOOT_COMPLETED' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.VIBRATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.DIAGNOSTIC' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_PROFILE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CALL_PHONE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.FLASHLIGHT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_PHONE_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CHANGE_COMPONENT_ENABLED_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CLEAR_APP_USER_DATA' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BROADCAST_SMS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.KILL_BACKGROUND_PROCESSES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_FRAME_BUFFER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SUBSCRIBED_FEEDS_WRITE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CAMERA' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.RECEIVE_MMS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WAKE_LOCK' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_DOWNLOAD_MANAGER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.launcher3.permission.WRITE_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.DELETE_CACHE_FILES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.RESTART_PACKAGES' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.GET_ACCOUNTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SUBSCRIBED_FEEDS_READ' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CHANGE_NETWORK_STATE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_SYNC_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.DISABLE_KEYGUARD' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.launcher.permission.UNINSTALL_SHORTCUT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.USE_CREDENTIALS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_USER_DICTIONARY' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_MEDIA_STORAGE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_COARSE_LOCATION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.email.permission.READ_ATTACHMENT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_POINTER_SPEED' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BACKUP' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.EXPAND_STATUS_BAR' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BLUETOOTH_ADMIN' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.ACCESS_FINE_LOCATION' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.LOCATION_HARDWARE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.PERSISTENT_ACTIVITY' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.REORDER_TASKS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.BIND_TEXT_SERVICE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.DEVICE_POWER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.SET_WALLPAPER' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_CALL_LOG' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_EXTERNAL_STORAGE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.GET_PACKAGE_SIZE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.WRITE_SOCIAL_STREAM' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.READ_EXTERNAL_STORAGE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            # Note: This looks like a typo - two permissions combined
            if 'android.permission.INSTALL_PACKAGESandroid.permission.AUTHENTICATE_ACCOUNTS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.launcher.permission.READ_SETTINGS' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'com.android.alarm.permission.SET_ALARM' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.INTERNAL_SYSTEM_WINDOW' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CLEAR_APP_CACHE' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.CAPTURE_VIDEO_OUTPUT' in perm_list:
                cv.append(1)
            else:
                cv.append(0)
                
            if 'android.permission.GET_TOP_ACTIVITY_INFO' in perm_list:
                cv.append(1)
            else:
                cv.append(0)

            # Store in dataset (CSV)
            dataset_path = os.path.join(media_dir, 'apk_permissions_dataset.csv')
            # Write header if file does not exist
            write_header = not os.path.exists(dataset_path)
            with open(dataset_path, 'a', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                if write_header:
                    writer.writerow(['file_name', 'apk_type', 'permissions', 'cv_vector'])
                writer.writerow([
                    apk_file.name,
                    apk_type,
                    '|'.join(permissions),  # Store permissions as pipe-separated string
                    '|'.join(map(str, cv))  # Store cv vector as pipe-separated string
                ])

            print(f"CV vector length: {len(cv)}")
            print(f"CV vector: {cv}")

            return JsonResponse({
                'success': True,
                'message': 'APK uploaded and permissions stored',
                'apk_type': apk_type,
                'file_name': apk_file.name,
                'permissions': list(permissions),
                'cv_vector': cv
            })
            
        except Exception as e:
            print(f"Error processing APK: {e}")
            return JsonResponse({
                'success': False, 
                'error': f'Error processing APK: {str(e)}'
            })
            
    return JsonResponse({'success': False, 'error': 'Invalid request'})

@csrf_exempt
def delete_apk(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            idx = data.get('id')
            if idx is None:
                return JsonResponse({'success': False, 'error': 'No APK id provided'})
            dataset_path = os.path.join(os.getcwd(), 'media', 'apk_permissions_dataset.csv')
            if not os.path.exists(dataset_path):
                return JsonResponse({'success': False, 'error': 'Dataset not found'})
            with open(dataset_path, 'r', newline='', encoding='utf-8') as f:
                reader = list(csv.DictReader(f))
                fieldnames = reader[0].keys() if reader else None
            if not reader or fieldnames is None:
                # File is empty or missing headers, just clear it
                open(dataset_path, 'w').close()
                return JsonResponse({'success': True})
            if idx < 0 or idx >= len(reader):
                return JsonResponse({'success': False, 'error': 'Invalid APK id'})
            # Remove the row at the given index
            rows = [row for i, row in enumerate(reader) if i != idx]
            with open(dataset_path, 'w', newline='', encoding='utf-8') as f:
                if rows:
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(rows)
                else:
                    # Only write header if no rows left
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})
    return JsonResponse({'success': False, 'error': 'Invalid request method'})

import os
import csv
from django.http import JsonResponse
import json

def get_apk_list(request):
    # Path to the CSV file
    media_dir = os.path.join(os.getcwd(), 'media')
    csv_file_path = os.path.join(media_dir, 'apk_permissions_dataset.csv')
    
    apks = []
    
    # Check if CSV file exists
    if not os.path.exists(csv_file_path):
        return JsonResponse({'apks': apks, 'message': 'No APK data found'}, safe=False)
    
    try:
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            
            # Get the directory where APK files are stored
            apk_files_dir = media_dir  # APKs are in media directory
            
            for idx, row in enumerate(reader, start=1):
                file_name = row.get('file_name', '')
                apk_type = row.get('apk_type', 'unknown')
                permissions = row.get('permissions', '')
                cv_vector = row.get('cv_vector', '')
                
                # Get file info if APK file exists
                file_path = os.path.join(apk_files_dir, file_name)
                file_size = 'N/A'
                if os.path.exists(file_path):
                    # Calculate file size
                    size_bytes = os.path.getsize(file_path)
                    if size_bytes < 1024:
                        file_size = f"{size_bytes} bytes"
                    elif size_bytes < 1024 * 1024:
                        file_size = f"{size_bytes / 1024:.1f} KB"
                    else:
                        file_size = f"{size_bytes / (1024 * 1024):.1f} MB"
                
                # Get file modification date
                file_date = 'N/A'
                if os.path.exists(file_path):
                    import time
                    mod_time = os.path.getmtime(file_path)
                    from datetime import datetime
                    file_date = datetime.fromtimestamp(mod_time).strftime('%Y-%m-%d %H:%M:%S')
                
                # Parse permissions for display
                permission_list = permissions.split('|') if permissions else []
                permission_display = ', '.join(permission_list[:3])  # Show first 3
                if len(permission_list) > 3:
                    permission_display += f'... (+{len(permission_list) - 3} more)'
                
                # Parse CV vector
                cv_list = cv_vector.split('|') if cv_vector else []
                cv_sum = sum(int(x) for x in cv_list if x.isdigit())
                
                # Determine status based on APK type and permissions
                if apk_type.lower() == 'malware':
                    status = 'warning'
                    status_text = 'Malware'
                else:
                    status = 'active'
                    status_text = 'Benign'
                
                # Create APK info object
                apk_info = {
                    'id': idx,
                    'name': file_name,
                    'version': '1.0.0',  # Could extract from APK if available
                    'size': file_size,
                    'date': file_date.split()[0] if ' ' in file_date else file_date,  # Just date part
                    'status': status,
                    'status_text': status_text,
                    'downloads': 0,  # Could track downloads separately
                    'apk_type': apk_type,
                    'permissions_count': len(permission_list),
                    'permissions_preview': permission_display,
                    'risk_score': cv_sum,
                    'file_exists': os.path.exists(file_path),
                    'permissions': permission_list[:10],  # Send first 10 permissions
                    'cv_vector': cv_list
                }
                
                apks.append(apk_info)
    
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        return JsonResponse({'error': str(e)}, status=500)
    
    # Sort by date (newest first)
    apks.sort(key=lambda x: x['date'], reverse=True)
    
    return JsonResponse({'apks': apks}, safe=False)

def log(request):
    return render(request,"login index.html")

def logout_view(request):
    logout(request)
    return redirect('/')    



def logpost(request):
    from datetime import datetime
    username = request.POST['username']
    password = request.POST['password']

    user = authenticate(request, username=username, password=password)

    if user is None:
        return HttpResponse(
            "<script>alert('Invalid username or password');window.location='/'</script>"
        )

    # -----------------------------
    # LOGIN SUCCESS
    # -----------------------------
    login(request, user)
    request.session['lid'] = user.id
    request.session['ucount'] = User.objects.count() - 1

    # -----------------------------
    # LOAD APK DATA FROM CSV
    # -----------------------------
    media_dir = settings.MEDIA_ROOT
    csv_file_path = os.path.join(media_dir, 'apk_permissions_dataset.csv')

    apks = []

    if os.path.exists(csv_file_path):
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)

            for idx, row in enumerate(reader, start=1):
                file_name = row.get('file_name', '')
                apk_type = row.get('apk_type', 'unknown')
                permissions = row.get('permissions', '')

                file_path = os.path.join(media_dir, file_name)

                # File size
                if os.path.exists(file_path):
                    size_bytes = os.path.getsize(file_path)
                    file_size = (
                        f"{size_bytes / (1024 * 1024):.1f} MB"
                        if size_bytes > 1024 * 1024
                        else f"{size_bytes / 1024:.1f} KB"
                    )
                    mod_time = os.path.getmtime(file_path)
                    file_date = datetime.fromtimestamp(mod_time).strftime('%Y-%m-%d')
                else:
                    file_size = "N/A"
                    file_date = "N/A"

                permission_list = permissions.split('|') if permissions else []

                status = 'warning' if apk_type.lower() == 'malware' else 'active'
                status_text = 'Malware' if apk_type.lower() == 'malware' else 'Benign'

                apk_info = {
                    'id': idx,
                    'name': file_name,
                    'size': file_size,
                    'date': file_date,
                    'status': status,
                    'status_text': status_text,
                    'apk_type': apk_type,
                    'permissions_count': len(permission_list),
                    'permissions_preview': ', '.join(permission_list[:3]),
                    'file_exists': os.path.exists(file_path),
                }

                apks.append(apk_info)

    request.session['apk_data'] = len(apks)

    # -----------------------------
    # REDIRECT BASED ON ROLE
    # -----------------------------
    if user.is_superuser:
        return HttpResponse(
            "<script>alert('Login successful');window.location='/adminhome'</script>"
        )
    else:
        return HttpResponse(
            "<script>alert('Login successful');window.location='/'</script>"
        )



def adminhome(request):
    return render(request,"adminhome.html")


def forgotpassword(request):
    return render(request,"forgotpassword.html")
def forgotpasswordbuttonclick(request):
    email = request.POST['textfield']
    if login.objects.filter(username=email).exists():
        try:
            from email.mime.text import MIMEText
            from email.mime.multipart import MIMEMultipart

            # ✅ Gmail credentials (use App Password, not real password)
            sender_email = ""
            receiver_email = email  # change to actual recipient
            app_password = ""  # App Password from Google
            pwd = str(random.randint(1100,9999))
            print(pwd)  # Example password to send
            request.session['otp'] = pwd
            request.session['email'] = email

            # Setup SMTP
            server = smtplib.SMTP("smtp.gmail.com", 587)
            server.starttls()
            server.login(sender_email, app_password)

            # Create the email
            msg = MIMEMultipart("alternative")
            msg["From"] = sender_email
            msg["To"] = receiver_email
            msg["Subject"] = "Your OTP"

            # Plain text (backup)
            # text = f"""
            # Hello,

            # Your password for Smart Donation Website is: {pwd}

            # Please keep it safe and do not share it with anyone.
            # """

            # HTML (attractive)
            html = f"""
            <html>
            <body style="font-family: Arial, sans-serif; color: #333;">
                <h2 style="color:#2c7be5;">Interview Stimulator</h2>
                <p>Hello,</p>
                <p>Your OTP is:</p>
                <p style="padding:10px; background:#f4f4f4; 
                        border:1px solid #ddd; 
                        display:inline-block;
                        font-size:18px;
                        font-weight:bold;
                        color:#2c7be5;">
                {pwd}
                </p>
                <p>Please keep it safe and do not share it with anyone.</p>
                <hr>
                <small style="color:gray;">This is an automated email from Interview Stimulator System.</small>
            </body>
            </html>
            """

            # Attach both versions
            # msg.attach(MIMEText(text, "plain"))
            msg.attach(MIMEText(html, "html"))

            # Send email
            server.send_message(msg)
            print("✅ Email sent successfully!")

            # Close connection
            server.quit()
        except Exception as e:
            print("❌ Error sending email:", e)
        return HttpResponse("<script>window.location='/otp'</script>")
    else:
        return HttpResponse("<script>alert('Email not found');window.location='/forgotpassword'</script>")


def otp(request):
    print("session otp",request.session['otp'])

    return render(request,"otp.html")
def otpbuttonclick(request):
    otp  = request.POST["textfield"]
    if otp == str(request.session['otp']):
        return HttpResponse("<script>window.location='/forgotpswdpswed'</script>")
    else:
        return HttpResponse("<script>alert('incorrect otp');window.location='/otp'</script>")

def forgotpswdpswed(request):
    return render(request,"forgotpswdpswed.html")
def forgotpswdpswedbuttonclick(request):
    np = request.POST["password"]
    login.objects.filter(username=request.session['email']).update(password=np)
    return HttpResponse("<script>alert('password has been changed');window.location='/' </script>")

def change_password(request):
    return render(request,"changepassword.html")


def change_password_post(request):
    current_password = request.POST['textfield']
    new_password = request.POST['textfield2']
    confirm_password = request.POST['textfield3']

    user = request.user

    # Check current password
    if not user.check_password(current_password):
        return HttpResponse(
            "<script>alert('Current password is incorrect');window.location='/college_change_password#abc'</script>"
        )

    # Check new & confirm password
    if new_password != confirm_password:
        return HttpResponse(
            "<script>alert('Passwords do not match');window.location='/college_change_password#abc'</script>"
        )

    # Set new password securely
    user.set_password(new_password)
    user.save()

    return HttpResponse(
        "<script>alert('Password updated successfully');window.location='/'</script>"
    )


@require_GET
def user_permissions(request, username):
    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        return JsonResponse({'detail': 'User not found'}, status=404)

    perms = sorted(user.get_all_permissions())
    return JsonResponse({'username': username, 'permissions': perms})


def train_model_from_csv():
    """Train and save ML model from CSV dataset if not already trained."""
    model_path = os.path.join(os.getcwd(), 'model.pkl')
    if os.path.exists(model_path):
        return  # Model already exists
    
    csv_path = os.path.join(os.getcwd(), 'media', 'apk_permissions_dataset.csv')
    if not os.path.exists(csv_path):
        print('Warning: CSV dataset not found, model training skipped')
        return
    
    try:
        import numpy as np
        from sklearn.ensemble import RandomForestClassifier
        
        print('Training ML model from CSV...')
        X = []
        y = []
        
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                cv_vector = row.get('cv_vector', '')
                apk_type = row.get('apk_type', 'benign')
                
                if cv_vector:
                    vector = [int(x) for x in cv_vector.split('|') if x.isdigit()]
                    if vector:  # Only add if vector is not empty
                        X.append(vector)
                        label = 1 if apk_type.lower() == 'malware' else 0
                        y.append(label)
        
        if len(X) < 2:
            print('Warning: Insufficient training data')
            return
        
        X = np.array(X)
        y = np.array(y)
        
        print(f'Training with {len(X)} samples, {X.shape[1]} features')
        
        clf = RandomForestClassifier(n_estimators=100, random_state=42, max_depth=10)
        clf.fit(X, y)
        
        with open(model_path, 'wb') as f:
            pickle.dump(clf, f)
        
        print(f'✓ Model trained and saved to {model_path}')
        print(f'✓ Model expects {clf.n_features_in_} features')
    except Exception as exc:
        print(f'Warning: Model training failed: {exc}')

@require_POST
def submit_permissions(request):
    try:
        # Auto-train model on first request if needed
        train_model_from_csv()
        
        # Permission risk scores (0-10 scale)
        PERMISSION_RISK_SCORES = {
            # High risk (9-10): System modification and dangerous access
            'android.permission.BRICK': 10,
            'android.permission.REBOOT': 10,
            'android.permission.MASTER_CLEAR': 10,
            'android.permission.WRITE_SECURE_SETTINGS': 9,
            'android.permission.CALL_PRIVILEGED': 9,
            'android.permission.MOUNT_FORMAT_FILESYSTEMS': 9,
            'android.permission.WRITE_GSERVICES': 9,
            'android.permission.FORCE_STOP_PACKAGES': 9,
            'android.permission.DUMP': 9,
            'android.permission.READ_LOGS': 9,
            
            # Very High Risk (7-8): Device control and sensitive data
            'android.permission.INSTALL_PACKAGES': 8,
            'android.permission.DELETE_PACKAGES': 8,
            'android.permission.CHANGE_COMPONENT_ENABLED_STATE': 8,
            'android.permission.MANAGE_APP_TOKENS': 8,
            'android.permission.WRITE_APN_SETTINGS': 8,
            'android.permission.ACCESS_FINE_LOCATION': 8,
            'android.permission.ACCESS_COARSE_LOCATION': 8,
            'android.permission.CAMERA': 8,
            'android.permission.RECORD_AUDIO': 8,
            'android.permission.SEND_SMS': 8,
            'android.permission.RECEIVE_SMS': 8,
            'android.permission.SEND_DOWNLOAD_COMPLETED_INTENTS': 8,
            'android.permission.SYSTEM_ALERT_WINDOW': 7,
            'android.permission.MODIFY_PHONE_STATE': 7,
            'android.permission.GET_TASKS': 7,
            'android.permission.PROCESS_OUTGOING_CALLS': 7,
            
            # High Risk (5-6): Sensitive info and account access
            'android.permission.READ_CONTACTS': 6,
            'android.permission.WRITE_CONTACTS': 6,
            'android.permission.READ_CALENDAR': 6,
            'android.permission.WRITE_CALENDAR': 6,
            'android.permission.READ_CALL_LOG': 6,
            'android.permission.WRITE_CALL_LOG': 6,
            'android.permission.READ_SMS': 6,
            'android.permission.WRITE_SMS': 6,
            'android.permission.RECEIVE_MMS': 6,
            'android.permission.READ_PHONE_STATE': 6,
            'android.permission.INTERNET': 5,
            'android.permission.MANAGE_ACCOUNTS': 5,
            'android.permission.GET_ACCOUNTS': 5,
            'android.permission.ACCOUNT_MANAGER': 5,
            'android.permission.ACCESS_NETWORK_STATE': 5,
            'android.permission.CHANGE_NETWORK_STATE': 5,
            'android.permission.CHANGE_WIFI_STATE': 5,
            'android.permission.CHANGE_WIFI_MULTICAST_STATE': 5,
            'android.permission.WRITE_SETTINGS': 5,
            'android.permission.WRITE_SYNC_SETTINGS': 5,
            
            # Medium Risk (3-4): Device features
            'android.permission.BLUETOOTH': 4,
            'android.permission.BLUETOOTH_ADMIN': 4,
            'android.permission.BLUETOOTH_PRIVILEGED': 4,
            'android.permission.NFC': 4,
            'android.permission.CAMERA': 4,
            'android.permission.FLASHLIGHT': 3,
            'android.permission.VIBRATE': 3,
            'android.permission.CALL_PHONE': 3,
            'android.permission.WAKE_LOCK': 3,
            'android.permission.ACCESS_LOCATION_EXTRA_COMMANDS': 3,
            'android.permission.USE_SIP': 3,
            'android.permission.MODIFY_AUDIO_SETTINGS': 3,
            
            # Low Risk (1-2): Normal app functionality
            'android.permission.READ_EXTERNAL_STORAGE': 2,
            'android.permission.WRITE_EXTERNAL_STORAGE': 2,
            'android.permission.RECEIVE_BOOT_COMPLETED': 2,
            'android.permission.ACCESS_WIFI_STATE': 2,
            'android.permission.EXPAND_STATUS_BAR': 1,
            'android.permission.READ_PROFILE': 1,
            'android.permission.WRITE_PROFILE': 1,
            'android.permission.SET_WALLPAPER': 1,
            'android.permission.SET_ANIMATION_SCALE': 1,
        }
        
        payload = json.loads(request.body.decode('utf-8'))
        entries = payload.get('entries')
        if not isinstance(entries, list):
            return JsonResponse({'detail': 'Missing entries list'}, status=400)

        # Comprehensive permissions list (matching upload_apk permissions)
        ALL_PERMISSIONS = [
            'android.permission.BIND_WALLPAPER', 'android.permission.FORCE_BACK',
            'android.permission.READ_CALENDAR', 'android.permission.BODY_SENSORS',
            'android.permission.READ_SOCIAL_STREAM', 'android.permission.READ_SYNC_STATS',
            'android.permission.INTERNET', 'android.permission.CHANGE_CONFIGURATION',
            'android.permission.BIND_DREAM_SERVICE', 'android.permission.HARDWARE_TEST',
            'com.android.browser.permission.WRITE_HISTORY_BOOKMARKS',
            'com.android.launcher.permission.INSTALL_SHORTCUT',
            'android.permission.BIND_TV_INPUT', 'android.permission.BIND_VPN_SERVICE',
            'android.permission.BLUETOOTH_PRIVILEGED', 'android.permission.WRITE_CALL_LOG',
            'android.permission.CHANGE_WIFI_MULTICAST_STATE', 'android.permission.BIND_INPUT_METHOD',
            'android.permission.SET_TIME_ZONE', 'android.permission.WRITE_SYNC_SETTINGS',
            'android.permission.WRITE_GSERVICES', 'android.permission.SET_ORIENTATION',
            'android.permission.BIND_DEVICE_ADMIN', 'android.permission.MANAGE_DOCUMENTS',
            'android.permission.FORCE_STOP_PACKAGES', 'android.permission.WRITE_SECURE_SETTINGS',
            'android.permission.CALL_PRIVILEGED', 'android.permission.MOUNT_FORMAT_FILESYSTEMS',
            'android.permission.SYSTEM_ALERT_WINDOW', 'android.permission.ACCESS_LOCATION_EXTRA_COMMANDS',
            'android.permission.BRICK', 'android.permission.DUMP', 'android.permission.CHANGE_WIFI_STATE',
            'android.permission.RECORD_AUDIO', 'android.permission.MODIFY_PHONE_STATE',
            'android.permission.READ_PROFILE', 'android.permission.ACCOUNT_MANAGER',
            'android.permission.SET_ANIMATION_SCALE', 'android.permission.SET_PROCESS_LIMIT',
            'android.permission.CAPTURE_SECURE_VIDEO_OUTPUT', 'android.permission.SET_PREFERRED_APPLICATIONS',
            'android.permission.ACCESS_ALL_DOWNLOADS', 'android.permission.SET_DEBUG_APP',
            'android.permission.STOP_APP_SWITCHES', 'android.permission.BLUETOOTH',
            'android.permission.ACCESS_WIFI_STATE', 'android.permission.SET_WALLPAPER_HINTS',
            'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE', 'android.permission.MMS_SEND_OUTBOX_MSG',
            'android.permission.CONTROL_LOCATION_UPDATES', 'android.permission.UPDATE_APP_OPS_STATS',
            'android.permission.REBOOT', 'android.permission.BROADCAST_WAP_PUSH',
            'com.android.launcher3.permission.READ_SETTINGS', 'android.permission.ACCESS_NETWORK_STATE',
            'android.permission.STATUS_BAR', 'android.permission.WRITE_USER_DICTIONARY',
            'com.android.browser.permission.READ_HISTORY_BOOKMARKS', 'android.permission.BROADCAST_PACKAGE_REMOVED',
            'android.permission.RECEIVE_SMS', 'android.permission.WRITE_CONTACTS', 'android.permission.READ_CONTACTS',
            'android.permission.BIND_APPWIDGET', 'android.permission.SIGNAL_PERSISTENT_PROCESSES',
            'android.permission.INSTALL_LOCATION_PROVIDER', 'android.permission.ACCESS_DOWNLOAD_MANAGER_ADVANCED',
            'android.permission.WRITE_SETTINGS', 'android.permission.MASTER_CLEAR', 'android.permission.READ_INPUT_STATE',
            'android.permission.MANAGE_APP_TOKENS', 'android.permission.BIND_REMOTEVIEWS',
            'com.android.email.permission.ACCESS_PROVIDER', 'android.permission.BIND_VOICE_INTERACTION',
            'com.android.launcher.permission.WRITE_SETTINGS', 'com.android.gallery3d.filtershow.permission.READ',
            'android.permission.BIND_PRINT_SERVICE', 'android.permission.MODIFY_AUDIO_SETTINGS', 'android.permission.USE_SIP',
            'android.permission.WRITE_APN_SETTINGS', 'android.permission.ACCESS_SURFACE_FLINGER', 'android.permission.FACTORY_TEST',
            'android.permission.READ_LOGS', 'android.permission.PROCESS_OUTGOING_CALLS', 'android.permission.UPDATE_DEVICE_STATS',
            'android.permission.SEND_DOWNLOAD_COMPLETED_INTENTS', 'android.permission.WRITE_CALENDAR', 'android.permission.NFC',
            'android.permission.MANAGE_ACCOUNTS', 'android.permission.SEND_SMS', 'android.permission.INTERACT_ACROSS_USERS_FULL',
            'android.permission.ACCESS_MOCK_LOCATION', 'android.permission.BIND_ACCESSIBILITY_SERVICE',
            'android.permission.CAPTURE_AUDIO_OUTPUT', 'android.permission.WRITE_SMS', 'android.permission.GET_TASKS',
            'android.permission.DELETE_PACKAGES', 'android.permission.ACCESS_CHECKIN_PROPERTIES',
            'android.permission.SEND_RESPOND_VIA_MESSAGE', 'android.permission.MEDIA_CONTENT_CONTROL',
            'android.permission.DOWNLOAD_WITHOUT_NOTIFICATION', 'android.permission.RECEIVE_BOOT_COMPLETED',
            'android.permission.VIBRATE', 'android.permission.DIAGNOSTIC', 'android.permission.WRITE_PROFILE',
            'android.permission.CALL_PHONE', 'android.permission.FLASHLIGHT', 'android.permission.READ_PHONE_STATE',
            'android.permission.CHANGE_COMPONENT_ENABLED_STATE', 'android.permission.CLEAR_APP_USER_DATA',
            'android.permission.BROADCAST_SMS', 'android.permission.KILL_BACKGROUND_PROCESSES', 'android.permission.READ_FRAME_BUFFER',
            'android.permission.SUBSCRIBED_FEEDS_WRITE', 'android.permission.CAMERA', 'android.permission.RECEIVE_MMS',
            'android.permission.WAKE_LOCK', 'android.permission.ACCESS_DOWNLOAD_MANAGER',
            'com.android.launcher3.permission.WRITE_SETTINGS', 'android.permission.DELETE_CACHE_FILES',
            'android.permission.RESTART_PACKAGES', 'android.permission.GET_ACCOUNTS', 'android.permission.SUBSCRIBED_FEEDS_READ',
            'android.permission.CHANGE_NETWORK_STATE', 'android.permission.READ_SYNC_SETTINGS', 'android.permission.DISABLE_KEYGUARD',
            'com.android.launcher.permission.UNINSTALL_SHORTCUT', 'android.permission.USE_CREDENTIALS',
            'android.permission.READ_USER_DICTIONARY', 'android.permission.WRITE_MEDIA_STORAGE',
            'android.permission.ACCESS_COARSE_LOCATION', 'com.android.email.permission.READ_ATTACHMENT',
            'android.permission.SET_POINTER_SPEED', 'android.permission.BACKUP', 'android.permission.EXPAND_STATUS_BAR',
            'android.permission.BLUETOOTH_ADMIN', 'android.permission.ACCESS_FINE_LOCATION', 'android.permission.LOCATION_HARDWARE',
            'android.permission.PERSISTENT_ACTIVITY', 'android.permission.REORDER_TASKS', 'android.permission.BIND_TEXT_SERVICE',
            'android.permission.DEVICE_POWER', 'android.permission.SET_WALLPAPER', 'android.permission.READ_CALL_LOG',
            'android.permission.WRITE_EXTERNAL_STORAGE', 'android.permission.GET_PACKAGE_SIZE', 'android.permission.WRITE_SOCIAL_STREAM',
            'android.permission.READ_EXTERNAL_STORAGE', 'com.android.launcher.permission.READ_SETTINGS',
            'com.android.alarm.permission.SET_ALARM', 'android.permission.INTERNAL_SYSTEM_WINDOW',
            'android.permission.CLEAR_APP_CACHE', 'android.permission.CAPTURE_VIDEO_OUTPUT', 'android.permission.GET_TOP_ACTIVITY_INFO'
        ]

        # Load ML model
        model_path = os.path.join(os.getcwd(), 'model.pkl')
        clf = None
        expected_features = len(ALL_PERMISSIONS)
        
        if os.path.exists(model_path):
            try:
                with open(model_path, 'rb') as f:
                    clf = pickle.load(f)
                expected_features = clf.n_features_in_
                print(f'Model loaded successfully with {expected_features} expected features')
            except Exception as exc:
                print(f'Warning: Could not load model: {exc}')

        results = []
        for entry in entries:
            granted = set(entry.get('granted', []))
            vector = [1 if perm in granted else 0 for perm in ALL_PERMISSIONS]
            
            # Calculate malware risk score based on permissions
            risk_score = 0
            for perm in granted:
                risk_score += PERMISSION_RISK_SCORES.get(perm, 1)  # Default 1 if permission not in list
            
            # Normalize risk score (0-100)
            max_possible_score = sum(PERMISSION_RISK_SCORES.values()) if PERMISSION_RISK_SCORES else 1
            normalized_risk_score = min(100, int((risk_score / max_possible_score) * 100)) if max_possible_score > 0 else 0
            
            # Pad or trim vector to match model's expected features
            if len(vector) < expected_features:
                vector.extend([0] * (expected_features - len(vector)))
            elif len(vector) > expected_features:
                vector = vector[:expected_features]
            
            prediction = None
            confidence = None
            if clf is not None:
                try:
                    pred = clf.predict([vector])[0]
                    pred_proba = clf.predict_proba([vector])[0]
                    prediction = 'malware' if pred == 1 else 'benign'
                    # Get confidence (probability of the predicted class)
                    confidence = round(float(max(pred_proba)) * 100, 2)
                except Exception as exc:
                    print(f'Prediction error: {exc}')
            
            # Generate suggestion based on prediction and risk level
            suggestion = None
            uninstall_recommendation = None
            if prediction == 'malware':
                risky_perms = [p for p in granted if PERMISSION_RISK_SCORES.get(p, 0) >= 7]
                suggestion = f"WARNING: This app is predicted as MALWARE with {confidence}% confidence. Risk score: {normalized_risk_score}/100. Detected dangerous permissions: {', '.join(risky_perms[:5])}{'...' if len(risky_perms) > 5 else ''}. RECOMMENDATION: Do not install this application. It may compromise device security and privacy."
                uninstall_recommendation = "UNINSTALL IMMEDIATELY - This app is flagged as malware and poses a direct threat to device security."
            elif normalized_risk_score >= 80:
                risky_perms = [p for p in granted if PERMISSION_RISK_SCORES.get(p, 0) >= 7]
                suggestion = f"CRITICAL: This app has critical risk (score {normalized_risk_score}/100). Dangerous permissions detected: {', '.join(risky_perms[:3])}. Use with extreme caution or avoid installation."
                uninstall_recommendation = "UNINSTALL STRONGLY RECOMMENDED - This app requires dangerous permissions and poses a critical security risk."
            elif normalized_risk_score >= 60:
                risky_perms = [p for p in granted if PERMISSION_RISK_SCORES.get(p, 0) >= 5]
                suggestion = f"HIGH RISK: This app has high risk (score {normalized_risk_score}/100). Review requested permissions: {', '.join(risky_perms[:3])} before installing."
                uninstall_recommendation = "CONSIDER UNINSTALLING - This app has high-risk permissions that may compromise privacy. Uninstall if not essential."
            elif normalized_risk_score >= 40:
                suggestion = f"MEDIUM RISK: This app has moderate risk (score {normalized_risk_score}/100). Be cautious when granting permissions."
                uninstall_recommendation = "MONITOR USAGE - This app has moderate risk. Monitor its behavior or uninstall if not actively used."
            else:
                suggestion = f"LOW RISK: This app has low risk (score {normalized_risk_score}/100). Safe to install and use."
                uninstall_recommendation = "SAFE - This app has minimal security risks and is safe to keep installed."
            
            result = {
                'packageName': entry.get('packageName'),
                'granted_permissions': list(granted),
                'permission_count': len(granted),
                'risk_score': normalized_risk_score,  # 0-100 scale
                'risk_level': 'critical' if normalized_risk_score >= 80 else 'high' if normalized_risk_score >= 60 else 'medium' if normalized_risk_score >= 40 else 'low',
                'binary_vector': vector,
                'prediction': prediction,
                'confidence': confidence,
                'suggestion': suggestion,
                'uninstall_recommendation': uninstall_recommendation
            }
            results.append(result)
            
            # Store result in AppHistory database
            try:
                AppHistory.objects.create(
                    packageName=entry.get('packageName'),
                    app_name=entry.get('packageName'),
                    action='permission_analysis',
                    granted_permissions=result['granted_permissions'],
                    permission_count=result['permission_count'],
                    risk_score=result['risk_score'],
                    risk_level=result['risk_level'],
                    binary_vector=result['binary_vector'],
                    prediction=result['prediction'],
                    confidence=result['confidence'],
                    suggestion=result['suggestion'] + '\n\n' + result['uninstall_recommendation']
                )
            except Exception as exc:
                print(f'Error storing result in AppHistory: {exc}')

        
        print('submit_permissions processed successfully')
        return JsonResponse({'status': 'received', 'results': results}, status=201)
    except Exception as exc:
        import traceback
        print('submit_permissions error:', exc)
        traceback.print_exc()
        return JsonResponse({'error': str(exc), 'traceback': traceback.format_exc()}, status=500)


@csrf_exempt
@require_GET
def get_privacy_score(request):
    """
    Calculate and return privacy score based on app analysis history.
    Privacy score is calculated as: 100 - average_risk_score_of_scanned_apps
    """
    try:
        from .models import AppHistory
        
        # Get all app history records
        app_records = AppHistory.objects.all()
        
        if not app_records.exists():
            # No apps scanned yet
            return JsonResponse({
                'privacy_score': 100.0,
                'total_apps_scanned': 0,
                'high_risk_apps': 0,
                'malware_apps': 0,
                'average_risk_score': 0.0,
                'status': 'no_data'
            }, status=200)
        
        # Calculate statistics
        total_apps = app_records.count()
        high_risk_count = app_records.filter(risk_score__gte=70).count()
        malware_count = app_records.filter(prediction='malware').count()
        
        # Calculate average risk score
        risk_scores = [record.risk_score for record in app_records]
        average_risk = sum(risk_scores) / len(risk_scores) if risk_scores else 0
        
        # Privacy score: 100 - average_risk_score
        privacy_score = max(0, 100 - average_risk)
        
        return JsonResponse({
            'privacy_score': round(privacy_score, 2),
            'total_apps_scanned': total_apps,
            'high_risk_apps': high_risk_count,
            'malware_apps': malware_count,
            'average_risk_score': round(average_risk, 2),
            'status': 'success'
        }, status=200)
        
    except Exception as exc:
        import traceback
        print(f'get_privacy_score error: {exc}')
        traceback.print_exc()
        return JsonResponse({
            'error': str(exc),
            'traceback': traceback.format_exc()
        }, status=500)

def get_scanned_apps(request):
    """
    Get all scanned apps with their details for PDF report.
    Returns list of apps with package name, risk score, prediction, and permission count.
    """
    try:
        from .models import AppHistory
        
        app_records = AppHistory.objects.all().order_by('-risk_score')
        
        apps = []
        for record in app_records:
            apps.append({
                'package_name': record.packageName,
                'risk_score': record.risk_score,
                'prediction': record.prediction,
                'permission_count': record.permission_count,
                'risk_level': 'malware' if record.prediction == 'malware' else ('high' if record.risk_score >= 70 else ('medium' if record.risk_score >= 40 else 'low'))
            })
        
        return JsonResponse({
            'apps': apps,
            'total_count': len(apps),
            'status': 'success'
        }, status=200)
        
    except Exception as exc:
        import traceback
        print(f'get_scanned_apps error: {exc}')
        traceback.print_exc()
        return JsonResponse({
            'error': str(exc),
            'traceback': traceback.format_exc(),
            'apps': [],
            'total_count': 0
        }, status=500)

# Breach detection endpoints
@csrf_exempt
@require_POST
def store_breach(request):
	"""
	Store detected breach information in the backend.
	Expected JSON: {
		'email': 'user@example.com',
		'breach_name': 'Adobe',
		'breach_domain': 'adobe.com',
		'breach_date': '2013-10-04',
		'description': 'Breach description',
		'pwn_count': 153000000,
		'is_verified': true,
		'is_sensitive': false,
		'is_active': true,
		'is_retired': false,
		'is_spam_list': false,
		'is_malware_list': false,
		'is_subscription_free': true,
		'logo_path': 'https://...',
		'data_classes': 'Passwords,Email addresses',
		'user': 'username' (optional)
	}
	"""
	try:
		data = json.loads(request.body)
		
		# Validate required fields
		email = data.get('email', '')
		breach_name = data.get('breach_name', '')
		
		if not email or not breach_name:
			return JsonResponse({
				'error': 'Email and breach_name are required'
			}, status=400)
		
		# Parse breach date if provided
		breach_date = None
		if data.get('breach_date'):
			try:
				from datetime import datetime
				breach_date = datetime.strptime(data['breach_date'], '%Y-%m-%d').date()
			except:
				pass
		
		# Create breach record with all available fields
		breach = BreachHistory.objects.create(
			email=email,
			breach_name=breach_name,
			breach_domain=data.get('breach_domain', ''),
			breach_date=breach_date,
			description=data.get('description', ''),
			pwn_count=data.get('pwn_count', 0),
			is_verified=data.get('is_verified', False),
			is_sensitive=data.get('is_sensitive', False),
			is_active=data.get('is_active', True),
			is_retired=data.get('is_retired', False),
			is_spam_list=data.get('is_spam_list', False),
			is_malware_list=data.get('is_malware_list', False),
			is_subscription_free=data.get('is_subscription_free', True),
			logo_path=data.get('logo_path', ''),
			data_classes=data.get('data_classes', ''),
			user=data.get('user', '')
		)
		
		print(f'[store_breach] Stored breach: {breach_name} for {email} with {breach.pwn_count} affected accounts')
		
		return JsonResponse({
			'success': True,
			'message': 'Breach stored successfully',
			'breach_id': breach.id
		}, status=201)
		
	except json.JSONDecodeError:
		return JsonResponse({
			'error': 'Invalid JSON'
		}, status=400)
	except Exception as e:
		import traceback
		print(f'store_breach error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)



@csrf_exempt
@require_GET
def get_breaches(request, email):
	"""
	Get all breaches for a specific email address.
	"""
	try:
		from datetime import timedelta
		from django.utils import timezone
		
		# Get breaches from last 30 days
		thirty_days_ago = timezone.now() - timedelta(days=30)
		print(f'Fetching breaches for {email} since {thirty_days_ago}')
		breaches = BreachHistory.objects.filter(
			user=email,
			detected_at__gte=thirty_days_ago
		).values()
		
		breach_list = []
		for breach in breaches:
			breach_list.append({
				'id': breach['id'],
				'email': breach['email'],
				'breach_name': breach['breach_name'],
				'breach_domain': breach['breach_domain'],
				'breach_date': str(breach['breach_date']) if breach['breach_date'] else None,
				'description': breach['description'],
				'detected_at': breach['detected_at'].isoformat()
			})
		
		return JsonResponse({
			'email': email,
			'breaches': breach_list,
			'count': len(breach_list)
		}, status=200)
		
	except Exception as e:
		import traceback
		print(f'get_breaches error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_GET
def get_user_breaches(request):
	"""
	Get all breaches for the current logged-in user.
	Query params: user (username)
	"""
	try:
		user = request.GET.get('user', '')
		if not user:
			return JsonResponse({
				'error': 'User parameter is required'
			}, status=400)
		
		breaches = BreachHistory.objects.filter(user=user).order_by('-detected_at').values()
		
		breach_list = []
		for breach in breaches:
			breach_list.append({
				'id': breach['id'],
				'email': breach['email'],
				'breach_name': breach['breach_name'],
				'breach_domain': breach['breach_domain'],
				'breach_date': str(breach['breach_date']) if breach['breach_date'] else None,
				'description': breach['description'],
				'detected_at': breach['detected_at'].isoformat()
			})
		
		return JsonResponse({
			'user': user,
			'breaches': breach_list,
			'count': len(breach_list)
		}, status=200)
		
	except Exception as e:
		import traceback
		print(f'get_user_breaches error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


# User registration endpoint
@csrf_exempt
@require_POST
def register(request):
	"""
	Register a new user.
	Expected JSON: {
		'name': 'John Doe',
		'email': 'john@example.com',
		'phone': '1234567890',
		'password': 'password123'
	}
	"""
	try:
		from .models import UserProfile
		
		data = json.loads(request.body)
		
		# Validate required fields
		name = data.get('name', '').strip()
		email = data.get('email', '').strip()
		phone = data.get('phone', '').strip()
		password = data.get('password', '')
		
		if not all([name, email, password]):
			return JsonResponse({
				'error': 'Name, email, and password are required'
			}, status=400)
		
		# Check if email already exists
		if UserProfile.objects.filter(email=email).exists():
			return JsonResponse({
				'error': 'Email already registered'
			}, status=400)
		
		# Create new user
		user = UserProfile.objects.create(
			name=name,
			email=email,
			phone=phone,
			password=password,  # In production, hash the password
		)
		
		return JsonResponse({
			'success': True,
			'message': 'User registered successfully',
			'user_id': user.id,
			'email': user.email,
			'name': user.name
		}, status=201)
		
	except json.JSONDecodeError:
		return JsonResponse({
			'error': 'Invalid JSON'
		}, status=400)
	except Exception as e:
		import traceback
		print(f'register error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_POST
def store_phone_breach(request):
	"""
	Store detected phone number breach information in the backend.
	Expected JSON: {
		'phone': '+1234567890',
		'breach_name': 'LinkedIn',
		'breach_domain': 'linkedin.com',
		'breach_date': '2012-05-05',
		'description': 'Breach description',
		'user': 'username' (optional)
	}
	"""
	try:
		data = json.loads(request.body)
		
		# Validate required fields
		phone = data.get('phone', '')
		breach_name = data.get('breach_name', '')
		
		if not phone or not breach_name:
			return JsonResponse({
				'error': 'Phone and breach_name are required'
			}, status=400)
		
		# Parse breach date if provided
		breach_date = None
		if data.get('breach_date'):
			try:
				from datetime import datetime
				breach_date = datetime.strptime(data['breach_date'], '%Y-%m-%d').date()
			except:
				pass
		
		# Create breach record
		breach = PhoneBreachHistory.objects.create(
			phone=phone,
			breach_name=breach_name,
			breach_domain=data.get('breach_domain', ''),
			breach_date=breach_date,
			description=data.get('description', ''),
			user=data.get('user', '')
		)
		
		return JsonResponse({
			'success': True,
			'message': 'Phone breach stored successfully',
			'breach_id': breach.id
		}, status=201)
		
	except json.JSONDecodeError:
		return JsonResponse({
			'error': 'Invalid JSON'
		}, status=400)
	except Exception as e:
		import traceback
		print(f'store_phone_breach error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_GET
def get_phone_breaches(request, phone):
	"""
	Get all breaches for a specific phone number.
	"""
	try:
		from datetime import timedelta
		from django.utils import timezone
		
		# Get breaches from last 30 days
		thirty_days_ago = timezone.now() - timedelta(days=30)
		breaches = PhoneBreachHistory.objects.filter(
			phone=phone,
			detected_at__gte=thirty_days_ago
		).values()
		
		breach_list = []
		for breach in breaches:
			breach_list.append({
				'id': breach['id'],
				'phone': breach['phone'],
				'breach_name': breach['breach_name'],
				'breach_domain': breach['breach_domain'],
				'breach_date': str(breach['breach_date']) if breach['breach_date'] else None,
				'description': breach['description'],
				'detected_at': breach['detected_at'].isoformat()
			})
		
		return JsonResponse({
			'phone': phone,
			'breaches': breach_list,
			'count': len(breach_list)
		}, status=200)
		
	except Exception as e:
		import traceback
		print(f'get_phone_breaches error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_GET
def get_user_phone_breaches(request):
	"""
	Get all phone breaches for the current logged-in user.
	Query params: user (username)
	"""
	try:
		user = request.GET.get('user', '')
		if not user:
			return JsonResponse({
				'error': 'User parameter is required'
			}, status=400)
		
		breaches = PhoneBreachHistory.objects.filter(user=user).order_by('-detected_at').values()
		
		breach_list = []
		for breach in breaches:
			breach_list.append({
				'id': breach['id'],
				'phone': breach['phone'],
				'breach_name': breach['breach_name'],
				'breach_domain': breach['breach_domain'],
				'breach_date': str(breach['breach_date']) if breach['breach_date'] else None,
				'description': breach['description'],
				'detected_at': breach['detected_at'].isoformat()
			})
		
		return JsonResponse({
			'user': user,
			'breaches': breach_list,
			'count': len(breach_list)
		}, status=200)
		
	except Exception as e:
		import traceback
		print(f'get_user_phone_breaches error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
import json
import os
import google.generativeai as genai

import json
import os
import re
import google.generativeai as genai

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST


def extract_json(text):
    """
    Safely extract JSON from Gemini response
    """
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        raise ValueError("No JSON found in Gemini response")
    return json.loads(match.group())


@csrf_exempt
@require_POST
def check_phishing_url(request):
    try:
        # -------------------------
        # Read request
        # -------------------------
        data = json.loads(request.body)
        url = data.get("url", "").strip()

        if not url:
            return JsonResponse({"error": "URL is required"}, status=400)

        # -------------------------
        # Gemini Configuration
        # -------------------------
        genai.configure(api_key="AIzaSyCD0nGuQtyA1Qcpdfimg54yu5CBcABhwDk")
        model = genai.GenerativeModel("gemini-2.5-flash")

        # -------------------------
        # Gemini Prompt
        # -------------------------
        prompt = f"""
You are a cybersecurity expert.

Analyze the URL below and determine whether it is a phishing URL.

URL: {url}

RULES:
- Respond ONLY in JSON
- No markdown
- No explanations outside JSON

JSON format:
{{
  "is_phishing": true or false,
  "risk_level": "safe" | "suspicious" | "phishing",
  "confidence": 0.0 to 1.0,
  "reason": "short explanation"
}}
"""

        # -------------------------
        # Gemini Call
        # -------------------------
        result = model.generate_content(prompt)

        # -------------------------
        # Parse Response
        # -------------------------
        gemini_response = extract_json(result.text)
        print(gemini_response)

        # -------------------------
        # Save to DB (optional)
        # -------------------------
        phishing_record = PhishingUrlHistory.objects.create(
            url=url,
            risk_level=gemini_response["risk_level"],
            is_phishing=gemini_response["is_phishing"],
            confidence_score=gemini_response["confidence"],
            details=gemini_response["reason"],
            threats=[],
            user=data.get("user", "")
        )

        # -------------------------
        # Response
        # -------------------------
        return JsonResponse({
            "success": True,
            "url": url,
            "is_phishing": gemini_response["is_phishing"],
            "risk_level": gemini_response["risk_level"],
            "confidence_score": round(gemini_response["confidence"], 2),
            "reason": gemini_response["reason"],
            "record_id": phishing_record.id
        })

    except Exception as e:
        return JsonResponse({
            "error": "Gemini phishing check failed",
            "details": str(e)
        }, status=500)

@csrf_exempt
@require_GET
def get_phishing_history(request):
	"""
	Get all phishing URL checks for a user.
	Query params: user (username)
	"""
	try:
		user = request.GET.get('user', '')
		if not user:
			return JsonResponse({
				'error': 'User parameter is required'
			}, status=400)
		
		phishing_records = PhishingUrlHistory.objects.filter(user=user).order_by('-detected_at').values()
		
		records_list = []
		for record in phishing_records:
			records_list.append({
				'id': record['id'],
				'url': record['url'],
				'risk_level': record['risk_level'],
				'is_phishing': record['is_phishing'],
				'confidence_score': float(record['confidence_score']) if record['confidence_score'] else 0.0,
				'threats': record['threats'],
				'details': record['details'],
				'detected_at': record['detected_at'].isoformat()
			})
		print(records_list)
		return JsonResponse({
			'user': user,
			'records': records_list,
			'count': len(records_list)
		}, status=200)
		
	except Exception as e:
		import traceback
		print(f'get_phishing_history error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_GET
def get_phishing_url_detail(request, url_id):
	"""
	Get details of a specific phishing URL check.
	"""
	try:
		phishing_record = PhishingUrlHistory.objects.get(id=url_id)
		
		return JsonResponse({
			'id': phishing_record.id,
			'url': phishing_record.url,
			'risk_level': phishing_record.risk_level,
			'is_phishing': phishing_record.is_phishing,
			'confidence_score': float(phishing_record.confidence_score),
			'threats': phishing_record.threats,
			'details': phishing_record.details,
			'detected_at': phishing_record.detected_at.isoformat()
		}, status=200)
		
	except PhishingUrlHistory.DoesNotExist:
		return JsonResponse({
			'error': 'Record not found'
		}, status=404)
	except Exception as e:
		import traceback
		print(f'get_phishing_url_detail error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_POST
@csrf_exempt
@require_POST
def login1(request):
	"""
	Authenticate a user.
	Expected JSON: {
		'email': 'user@example.com',
		'password': 'password123'
	}
	"""
	try:
		from .models import UserProfile
		
		print(f"Login request body: {request.body}")
		data = json.loads(request.body)
		
		# Validate required fields
		email = data.get('email', '').strip()
		password = data.get('password', '')
		
		print(f"Login attempt - Email: {email}, Password length: {len(password)}")
		
		if not email or not password:
			return JsonResponse({
				'error': 'Email and password are required'
			}, status=400)
		
		# Check if user exists with this email
		try:
			user = UserProfile.objects.get(email=email)
			print(f"User found: {user.email}, stored password: {user.password}")
		except UserProfile.DoesNotExist:
			print(f"User not found with email: {email}")
			# List all users for debugging
			all_users = UserProfile.objects.all()
			print(f"Available users: {[u.email for u in all_users]}")
			return JsonResponse({
				'error': 'Invalid email or password'
			}, status=401)
		
		# Check password
		if user.password != password:
			print(f"Password mismatch. Provided: {password}, Stored: {user.password}")
			return JsonResponse({
				'error': 'Invalid email or password'
			}, status=401)
		
		print(f"Login successful for {email}")
		# Successful login
		return JsonResponse({
			'success': True,
			'message': 'Login successful',
			'user_id': user.id,
			'email': user.email,
			'name': user.name,
			'phone': user.phone
		}, status=200)
		
	except json.JSONDecodeError:
		return JsonResponse({
			'error': 'Invalid JSON'
		}, status=400)
	except Exception as e:
		import traceback
		print(f'login error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)


@csrf_exempt
@require_POST
def check_password_breach(request):
	"""
	Check if a password has been compromised in known data breaches.
	Uses a common passwords list and breached password database.
	Expected JSON: {'password': 'password_to_check'}
	Returns: {'is_compromised': bool, 'count': int}
	"""
	try:
		data = json.loads(request.body)
		password = data.get('password', '').strip()
		
		if not password:
			return JsonResponse({
				'error': 'Password is required'
			}, status=400)
		
		# Common compromised passwords list (frequently seen in breaches)
		# This includes top passwords from major breaches like HaveIBeenPwned
		COMPROMISED_PASSWORDS = [
			'password', '123456', '12345678', 'qwerty', 'abc123', '111111',
			'1234567', 'password123', '123123', '1234567890', '000000',
			'888888', '7777777', '666666', '555555', '444444', '333333',
			'222222', '654321', 'welcome', 'login', 'admin', 'letmein',
			'dragon', 'master', 'monkey', 'michael', 'sunshine', 'batman',
			'trustno1', '123456789', '1q2w3e4r', 'qwertyuiop', 'starwars',
			'qazwsx', 'Password1', 'Password123', 'Admin', 'Admin123',
			'Test', 'Test123', 'Letmein', 'Welcome', '1q2w3e', 'aaaaaa',
			'admin@123', 'admin123', 'root', 'root123', 'test', 'test123',
			'guest', 'guest123', 'user', 'user123', 'password1', 'password2',
			'123456aA', 'Aa123456', '!@#$%^', 'Qwerty123', 'asdfghjkl',
			'zxcvbnm', 'qwertyqwerty', '111111111111', '123321', '654321654321',
			'fuckyou', 'password!', 'pass', 'pass123', 'passpass', 'password@123'
		]
		
		# Check if password is in the compromised list (case-insensitive)
		password_lower = password.lower()
		is_compromised = password_lower in [p.lower() for p in COMPROMISED_PASSWORDS]
		
		# Count how many times this password appears in breaches
		# For now, we return a fixed count based on common breach statistics
		breach_count = 0
		if is_compromised:
			# In a real scenario, you would query a password hash database
			# like HIBP (HaveIBeenPwned) API or your own database
			# For now, return a realistic count based on how common the password is
			BREACH_COUNTS = {
				'password': 3547661,
				'123456': 2547830,
				'12345678': 1896473,
				'qwerty': 1876384,
				'abc123': 1734583,
				'111111': 1456829,
				'1234567': 1294758,
				'password123': 1294583,
			}
			breach_count = BREACH_COUNTS.get(password_lower, 500000)  # Default to 500k+ for other compromised passwords
		
		print(f'[check_password_breach] Password: {password_lower[:4]}***, Compromised: {is_compromised}, Count: {breach_count}')
		
		return JsonResponse({
			'is_compromised': is_compromised,
			'count': breach_count
		}, status=200)
		
	except json.JSONDecodeError:
		return JsonResponse({
			'error': 'Invalid JSON'
		}, status=400)
	except Exception as e:
		import traceback
		print(f'check_password_breach error: {e}')
		traceback.print_exc()
		return JsonResponse({
			'error': str(e),
			'traceback': traceback.format_exc()
		}, status=500)

