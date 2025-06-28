(async function(query) {
    // Assume "query" is encoded
    if (!query) return;
    const searchUrl = 'https://github.com/search?q=' + query + '&type=repositories';
    try {
        const queryParts = query.split('/');
        let apiQuery;
        if (queryParts.length === 2) {
            apiQuery = 'repo:' + queryParts[0] + '/' + queryParts[1];
        } else {
            apiQuery = 'in:name ' + query;
        }
        const apiUrl = 'https://api.github.com/search/repositories?q=' + encodeURIComponent(apiQuery) + '&per_page=1';
        const response = await fetch(apiUrl);
        if (!response.ok) {
            window.location.href = searchUrl;
            return;
        }
        const data = await response.json();
        if (data.items && data.items.length > 0) {
            const repo = data.items[0];
            if (queryParts.length === 2) {
                if (repo.full_name.toLowerCase() === query.toLowerCase()) {
                    window.location.href = repo.html_url;
                    return;
                }
            } else {
                if (repo.name.toLowerCase() === query.toLowerCase()) {
                    window.location.href = repo.html_url;
                    return;
                }
            }
        }
        window.location.href = searchUrl;
    } catch (error) {
        window.location.href = searchUrl;
    }
})("PLACEHOLDER_SEARCH_TERMS");  // Replace with '{searchTerms}'