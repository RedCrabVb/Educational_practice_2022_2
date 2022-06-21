package ru.neoflex.app.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class HistoryActiveUserSimple {
    @Id
    private String uuid;
    private Long userId;
    private String userAgent;
    private String useSessionId;
    private Long lastActive;
}
