use lol_html::{element, HtmlRewriter, Settings};
use std::rc::Rc;
use std::cell::RefCell;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_uchar};
use std::ptr;

// Wrapper struct for FFI
pub struct RewriterWrapper {
    rewriter: Option<HtmlRewriter<'static, Box<dyn FnMut(&[u8]) + 'static>>>,
    output_buffer: Rc<RefCell<Vec<u8>>>,
}

// C FFI function - create new rewriter
#[no_mangle]
pub extern "C" fn html_rewriter_new() -> *mut RewriterWrapper {
    let output_buffer = Rc::new(RefCell::new(vec![]));
    let output_clone = output_buffer.clone();
    
    let rewriter = HtmlRewriter::new(
        Settings {
            element_content_handlers: vec![
                element!("a[href]", |el| {
                    if let Some(href) = el.get_attribute("href") {
                        let new_href = href.replace("http:", "https:");
                        let _ = el.set_attribute("href", &new_href);
                    }
                    Ok(())
                })
            ],
            ..Settings::new()
        },
        Box::new(move |c: &[u8]| {
            output_clone.borrow_mut().extend_from_slice(c);
        }) as Box<dyn FnMut(&[u8]) + 'static>
    );

    let wrapper = RewriterWrapper {
        rewriter: Some(rewriter),
        output_buffer,
    };
    
    Box::into_raw(Box::new(wrapper))
}

// C FFI function - process string data and return output
#[no_mangle]
pub extern "C" fn html_rewriter_transform_string(
    wrapper: *mut RewriterWrapper,
    input: *const c_char,
    input_len: usize,
    output: *mut *mut c_char,
    output_len: *mut usize
) -> c_int {
    if wrapper.is_null() || input.is_null() || output.is_null() || output_len.is_null() {
        return -1;
    }
    
    unsafe {
        let wrapper_ref = &mut *wrapper;
        
        if let Some(ref mut rewriter) = wrapper_ref.rewriter {
            // Convert C string to byte slice
            let input_slice = std::slice::from_raw_parts(input as *const u8, input_len);
            
            // Process string data
            if rewriter.write(input_slice).is_err() {
                return -1;
            }
            
            // Check output
            let mut buffer = wrapper_ref.output_buffer.borrow_mut();
            if !buffer.is_empty() {
                let result = String::from_utf8_lossy(&buffer).into_owned();
                buffer.clear();
                
                // Convert to C string
                if let Ok(c_string) = CString::new(result) {
                    let len = c_string.as_bytes().len();
                    let ptr = c_string.into_raw();
                    *output = ptr;
                    *output_len = len;
                    return 1; // Has output
                }
            }
        }
        
        *output = ptr::null_mut();
        *output_len = 0;
        0 // No output
    }
}

// C FFI function - finalize processing and get final output
#[no_mangle]
pub extern "C" fn html_rewriter_finalize(
    wrapper: *mut RewriterWrapper,
    output: *mut *mut c_char,
    output_len: *mut usize
) -> c_int {
    if wrapper.is_null() || output.is_null() || output_len.is_null() {
        return -1;
    }
    
    unsafe {
        let wrapper_ref = &mut *wrapper;
        
        if let Some(rewriter) = wrapper_ref.rewriter.take() {
            // End processing
            if rewriter.end().is_err() {
                return -1;
            }
            
            // Get final output
            let buffer = wrapper_ref.output_buffer.borrow();
            if !buffer.is_empty() {
                let result = String::from_utf8_lossy(&buffer).into_owned();
                
                if let Ok(c_string) = CString::new(result) {
                    let len = c_string.as_bytes().len();
                    let ptr = c_string.into_raw();
                    *output = ptr;
                    *output_len = len;
                    return 1;
                }
            }
        }
        
        *output = ptr::null_mut();
        *output_len = 0;
        0
    }
}

// C FFI function - free rewriter
#[no_mangle]
pub extern "C" fn html_rewriter_free(wrapper: *mut RewriterWrapper) {
    if !wrapper.is_null() {
        unsafe {
            let _ = Box::from_raw(wrapper);
        }
    }
}

// C FFI function - free string memory
#[no_mangle]
pub extern "C" fn html_rewriter_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}
