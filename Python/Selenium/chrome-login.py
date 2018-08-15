# packages: selenium, chromedriver
# downloaded chromedriver.exe from http://chromedriver.chromium.org/downloads

import time
from selenium import webdriver

browser = webdriver.Chrome('C:\Users\eddys\Documents\Programs\chromedriver.exe')
browser.get('https://team-avengers.timedev.intapp.com/Reports')
browser.find_element_by_id('kc-submit').click()
browser.find_element_by_id('username').send_keys('MYUSERNAME')
browser.find_element_by_id('password').send_keys('MYPASSWORD')
browser.find_element_by_id('kc-login').click()
