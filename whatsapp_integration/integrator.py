from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException, TimeoutException, WebDriverException
import time

try:
    # Set up the WebDriver
    driver = webdriver.Chrome()

    # Open WhatsApp Web
    driver.get('https://web.whatsapp.com/')

    # Wait for QR code scanning
    input("Press Enter after scanning the QR code")

    # Wait a bit for the page to load
    time.sleep(5)

    # Find the chat (change the chat name accordingly)
    chat_name = "CSE 1"
    
    try:
        # Locate the search box to find the chat
        search_box = driver.find_element(By.XPATH, '//div[@contenteditable="true"][@data-tab="3"]')
        search_box.click()
        search_box.send_keys(chat_name)
        time.sleep(2)  # Wait for search results

        # Click on the chat from the search results
        chat = driver.find_element(By.XPATH, f'//span[@title="{chat_name}"]')
        chat.click()

    except NoSuchElementException:
        print(f"Could not find the chat with the name '{chat_name}'")
        driver.quit()
        exit()

    # Wait for the messages to load (explicit wait)
    try:
        message_xpath = '//div[contains(@class,"message-in") or contains(@class,"message-out")]'
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, message_xpath)))
        time.sleep(3)  # Extra wait to make sure all messages are loaded

        # Read all the messages
        messages = driver.find_elements(By.XPATH, message_xpath)

        if not messages:
            print("No messages found in this chat.")
        else:
            print(f"Found {len(messages)} messages.")
            for message in messages:
                try:
                    # Check if it's a media message (e.g., document, image, video)
                    media_elements = message.find_elements(By.XPATH, './/span[contains(@data-testid, "media")]')
                    
                    if media_elements:
                        media_type = media_elements[0].get_attribute('data-testid')
                        
                        # Determine media type
                        if "image" in media_type:
                            media_type = "Image"
                            print("Media Type: Image")
                        elif "video" in media_type:
                            media_type = "Video"
                            print("Media Type: Video")
                        elif "document" in media_type:
                            media_type = "Document"
                            print("Media Type: Document")
                            
                            # Extract document details
                            filename_element = message.find_element(By.CSS_SELECTOR, "span._ao3e")  # Update selector as needed
                            filename = filename_element.text

                            pages_element = message.find_element(By.CSS_SELECTOR, "span[title*='pages']")
                            pages = pages_element.text

                            file_size_element = message.find_element(By.CSS_SELECTOR, "span[title*='MB']")
                            file_size = file_size_element.text

                            # Check if there is a caption for the media message
                            caption_elements = message.find_elements(By.XPATH, './/span[@class="selectable-text"]//span')
                            if caption_elements:
                                caption = ''.join([span.text for span in caption_elements])
                            else:
                                caption = "No caption"
                            
                            print(f"Document - Filename: {filename}, Pages: {pages}, File Size: {file_size}, Caption: {caption}")
                            continue  # Skip further processing since document info has been handled
                            
                        else:
                            print("Media Type: Other Media")
                    else:
                        # If it's not a media message, check for regular text messages
                        # Using the provided structure for regular messages
                        text_element = message.find_element(By.XPATH, './/div[contains(@class, "copyable-text")]//span[@class="selectable-text"]//span')
                        if text_element:
                            message_text = text_element.text
                            print(f"Regular Message: {message_text}")
                        else:
                            print("No text found in this message.")
                except NoSuchElementException:
                    print("Could not retrieve the message content.")

    except TimeoutException:
        print("Timed out waiting for messages to load.")

except WebDriverException as e:
    print(f"WebDriver error: {str(e)}")
finally:
    driver.quit()
