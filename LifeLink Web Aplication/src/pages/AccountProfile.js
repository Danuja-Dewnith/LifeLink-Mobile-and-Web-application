import React, { useEffect, useState } from 'react';
import axios from 'axios';

const AccountProfile = () => {
    const [hospitalData, setHospitalData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const hid = localStorage.getItem('hospitalId');

        if (!hid) {
            setLoading(false);
            return;
        }

        axios.get(`http://localhost:8083/api/hospitals/${hid}`)
            .then(res => {
                setHospitalData(res.data);
                setLoading(false);
            })
            .catch(err => {
                console.error("Fetch error:", err);
                setLoading(false);
            });

    }, []);

    if (loading) {
        return <div style={{ padding: '50px', textAlign: 'center' }}>Loading Profile...</div>;
    }

    if (!hospitalData) {
        return <div style={{ padding: '50px', textAlign: 'center' }}>
            No profile found. Please login again.
        </div>;
    }

    return (
        <div className="profile-wrapper">
            <div className="profile-card">
                <div className="profile-header">
                    <h2>Hospital Details</h2>
                    <p>Manage your account information</p>
                </div>

                <div className="profile-body">

                    <div className="info-group">
                        <label>Institution Name</label>
                        <p>{hospitalData.institutionName}</p>
                    </div>

                    <div className="info-group">
                        <label>Email Address</label>
                        <p>{hospitalData.officialEmail}</p>
                    </div>

                    <div className="info-group">
                        <label>Registration ID</label>
                        <p>{hospitalData.registrationId}</p>
                    </div>

                    <div className="info-group">
                        <label>Contact Number</label>
                        <p>{hospitalData.contactNumber}</p>
                    </div>

                    <div className="info-group">
                        <label>Address</label>
                        <p>{hospitalData.physicalAddress}</p>
                    </div>

                    <div className="info-group">
                        <label>Status</label>
                        <p>{hospitalData.status}</p>
                    </div>

                </div>
            </div>

            <style>{`
                .profile-wrapper {
                    padding: 50px;
                    background: #f4f7f6;
                    min-height: 100vh;
                    display: flex;
                    justify-content: center;
                }

                .profile-card {
                    background: white;
                    width: 100%;
                    max-width: 600px;
                    border-radius: 15px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.05);
                    overflow: hidden;
                }

                .profile-header {
                    background: #2196F3;
                    color: white;
                    padding: 30px;
                    text-align: center;
                }

                .profile-header h2 {
                    margin: 0;
                    font-size: 24px;
                }

                .profile-body {
                    padding: 30px;
                }

                .info-group {
                    margin-bottom: 20px;
                    border-bottom: 1px solid #eee;
                    padding-bottom: 10px;
                }

                .info-group label {
                    font-size: 12px;
                    color: #999;
                    text-transform: uppercase;
                    font-weight: bold;
                }

                .info-group p {
                    font-size: 18px;
                    color: #333;
                    margin: 5px 0 0 0;
                }
            `}</style>
        </div>
    );
};

export default AccountProfile;