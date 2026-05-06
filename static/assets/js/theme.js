document.addEventListener('DOMContentLoaded', function() {
    ApplyCollapsableNavigation();
    ApplyLoader();
    ApplyBackToTop();
    ApplyPostContentTransformation();
    ApplyLazyIframes();
});

function ApplyCollapsableNavigation() {
    var elems = document.querySelectorAll('.sidenav');
    M.Sidenav.init(elems);
}

function ApplyLoader() {
    $('.loader').addClass('active');
    $(window).on('load', function () {
        $('.loader').removeClass('active');
    });
}

function ApplyBackToTop() {
    var offset = 220;
    var duration = 500;

    jQuery(window).scroll(function () {
        if (jQuery(this).scrollTop() > offset) {
            jQuery('.back-to-top').fadeIn(duration);
        } else {
            jQuery('.back-to-top').fadeOut(duration);
        }
    });

    jQuery('.back-to-top').click(function (event) {
        event.preventDefault();
        jQuery('html, body').animate({ scrollTop: 0 }, duration);
        return false;
    });
}

function ApplyPostContentTransformation() {
    $(".post-content img").wrap(function () {
        return "<a class='fancybox-images' href='" + $(this).attr("src") + "' data-fancybox-group='defaultgallery' title='" + $(this).attr("alt") + "'>" + $(this).text() + "</a>";
    });

    $('.fancybox-images').fancybox();

    $('a[rel*="external"]').click(function () {
        $(this).attr('target', '_blank');
    });

    function fullImageResize() {
        $("img").each(function () {
            var contentWidth = $(".post-content").outerWidth();
            var imageWidth = $(this)[0].naturalWidth;
            if (imageWidth >= contentWidth) {
                $(this).addClass('full-img');
            } else {
                $(this).removeClass('full-img');
            }
        });
    }

    fullImageResize();

    $(window).on('resize', debounce(fullImageResize, 100));
}

function ApplyLazyIframes() {
    var iframes = document.querySelectorAll('iframe.lazy-iframe[data-src]');
    if (!iframes.length) return;
    if ('IntersectionObserver' in window) {
        var observer = new IntersectionObserver(function(entries) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    var iframe = entry.target;
                    iframe.src = iframe.dataset.src;
                    observer.unobserve(iframe);
                }
            });
        }, { rootMargin: '200px' });
        iframes.forEach(function(iframe) { observer.observe(iframe); });
    } else {
        iframes.forEach(function(iframe) { iframe.src = iframe.dataset.src; });
    }
}

function debounce(func, threshold) {
    var timeout;
    return function () {
        var obj = this, args = arguments;
        function delayed() {
            func.apply(obj, args);
            timeout = null;
        }
        clearTimeout(timeout);
        timeout = setTimeout(delayed, threshold || 100);
    };
}
