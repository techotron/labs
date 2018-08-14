# packages: selenium, chromedriver
# downloaded chromedriver.exe from http://chromedriver.chromium.org/downloads

import time
from selenium import webdriver

browser = webdriver.Chrome('C:\Users\eddys\Documents\Programs\chromedriver.exe')
# browser.get("https://team-avengers.timedev.intapp.com")
#
# try:
#     reportBtn = browser.find_element_by_name('Reports')
#     print('Found <%s> element with that class name!' % (reportBtn.tag_name))
# except:
#     print('Was not able to find an element with that name.')


browser.get('https://team-avengers.timedev.intapp.com/Reports')

try:
    emailTextBox = browser.find_element_by_id('email')
    print('Found <%s> element with that class name!' % (emailTextBox.tag_name))
    emailTextBox.click()
    emailTextBox.send_keys('admin')
    continueBtn = browser.find_element_by_id('kc-submit')
    continueBtn.click()
    
except:
    print('Was not able to find an element with that name.')