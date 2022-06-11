package ru.neoflex.app.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Date;

@Entity
@Table(name = "t_history_active_user")
@Getter
@Setter
@NoArgsConstructor
public class HistoryActiveUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long historyActiveUserId;
    private Long lastActive;
    private String useSessionId;
    private String userAgent;
    private Long userId;
}
