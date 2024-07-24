function load_pcs() {
    $.ajax({
        type: 'GET',
        url: '/api/wol_server.py?load=true',
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash'))
        },
        success: function(data) {
            if (data.success) {
                console.log("PC list loaded successfully");
                $('#pcs-list').html(data.pcs_list.map(pc => `
                    <li class="collection-item">
                        ${pc.hostname} (${pc.mac})
                        <a href="#!" class="secondary-content" onclick="wake_pc('${pc.mac}')"><i class="material-icons">power</i></a>
                        <a href="#!" class="secondary-content" onclick="delete_pc('${pc.mac}')"><i class="material-icons">delete</i></a>
                    </li>
                `).join(''));
            } else {
                console.log("Failed to load PC list");
                M.toast({html: data.message});
                $('#auth-modal').modal('open');
            }
        },
        error: function(xhr, status, error) {
            console.log("Error loading PC list", "status:", status, "error:", error);
            M.toast({html: 'Failed to load PC list. Please try again.'});
        },
        dataType: 'json'
    });
}

function wake_pc(mac) {
    $.ajax({
        type: 'GET',
        url: '/api/wol_server.py?wake=' + mac,
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash'))
        },
        success: function(data) {
            if (data.success) {
                console.log("Wake-up signal sent successfully to", mac);
                M.toast({html: data.message});
            } else {
                console.log("Failed to send wake-up signal to", mac);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error sending wake-up signal", "status:", status, "error:", error);
            M.toast({html: 'Failed to send wake-up signal. Please try again.'});
        },
        dataType: 'json'
    });
}

function delete_pc(mac, isReauth = false) {
    if (!isReauth) {
        pendingDeletionMac = mac;
        $('#auth-modal').modal('open');
        return;
    }

    $.ajax({
        type: 'GET',
        url: '/api/wol_server.py?delete=' + mac,
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash'))
        },
        success: function(data) {
            if (data.success) {
                console.log("PC deleted successfully", mac);
                load_pcs(); // Reload the PC list after deletion
                M.toast({html: data.message});
            } else {
                console.log("Failed to delete PC", mac);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error deleting PC", "status:", status, "error:", error);
            M.toast({html: 'Failed to delete PC. Please try again.'});
        },
        dataType: 'json'
    });
}

$('#add-pc-form').submit(function(event) {
    event.preventDefault();
    const mac = $('#mac').val();
    const ip = $('#ip').val();
    const hostname = $('#hostname').val();
    $.ajax({
        type: 'POST',
        url: '/api/wol_server.py',
        headers: {
            'Authorization': 'Basic ' + btoa(sessionStorage.getItem('username') + ':' + sessionStorage.getItem('passwordHash'))
        },
        data: {
            'mac': mac,
            'ip': ip,
            'hostname': hostname
        },
        success: function(data) {
            if (data.success) {
                console.log("PC added successfully", data);
                load_pcs(); // Reload the PC list after adding
                M.toast({html: data.message});
            } else {
                console.log("Failed to add PC", data);
                M.toast({html: data.message});
            }
        },
        error: function(xhr, status, error) {
            console.log("Error adding PC", "status:", status, "error:", error);
            M.toast({html: 'Failed to add PC. Please try again.'});
        },
        dataType: 'json'
    });
});